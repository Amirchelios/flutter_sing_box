import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sing_box/flutter_sing_box.dart';


class Base64Provider {
  static List<Outbound> provide(String data) {
    final base64String = data.replaceAll(RegExp(r'\s+'), '');
    // 检查长度是否为4的倍数
    if (base64String.length % 4 != 0) {
      throw Exception("Invalid base64 string");
    }
    RegExp base64RegExp = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    final isBase64 = base64RegExp.hasMatch(base64String);
    if (!isBase64) {
      throw Exception("Invalid base64 string");
    }
    String decodedString = utf8.decode(base64.decode(base64String));
    return provideLinks(decodedString);
  }

  static List<Outbound> provideLinks(String data) {
    final List<Outbound> outbounds = [];
    final List<String> lines = data.split(RegExp(r'[\r\n\s]+'));
    for (var line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      final uri = Uri.tryParse(line.trim());
      if (uri == null) {
        if (line.toUpperCase().startsWith('STATUS')) {
          // user info
          debugPrint(line);
        }
        continue;
      }
      final outbound = _parseUri(uri);
      if (outbound != null) {
        outbounds.add(outbound);
      }
    }
    return outbounds;
  }

  static Outbound? _parseUri(Uri uri) {
    switch (uri.scheme) {
      case ClashProxyType.hysteria2:
        return _parseHysteria2(uri);
      case ClashProxyType.hysteria:
        return _parseHysteria(uri);
      case ClashProxyType.anytls:
        return _parseAnytls(uri);
      case ClashProxyType.trojan:
        return _parseTrojan(uri);
      case OutboundType.vless:
        return _parseVless(uri);
      default:
        return null;
    }
  }
  static Outbound? _parseHysteria2(Uri uri) {
    try {
      Map<String, String> queryParams = uri.queryParameters;
      return Outbound(
        type: OutboundType.hysteria2,
        tag: Uri.decodeComponent(uri.fragment),
        server: uri.host,
        serverPort: uri.port,
        serverPorts: [queryParams['mport']!.replaceAll('-', ':')],
        password: uri.userInfo,
        tls: Tls(
          alpn: queryParams['alpn']?.isNotEmpty == true ? [queryParams['alpn']!] : ['h3'],
          enabled: true,
          insecure: queryParams['allowInsecure'] == '1',
          disableSni: !(queryParams['sni']?.isNotEmpty == true),
          serverName: queryParams['sni'] ?? '',
        ),
      );
    } catch (e) {
      return null;
    }
  }

  static Outbound? _parseHysteria(Uri uri) {
    try {
      Map<String, String> queryParams = uri.queryParameters;
      return Outbound(
        type: OutboundType.hysteria,
        tag: Uri.decodeComponent(uri.fragment),
        server: uri.host,
        serverPort: uri.port,
        serverPorts: [queryParams['mport']!.replaceAll('-', ':')],
        authStr: queryParams['auth'],
        tls: Tls(
          alpn: queryParams['alpn']?.isNotEmpty == true ? [queryParams['alpn']!] : ['h3'],
          enabled: true,
          insecure: queryParams['allowInsecure'] == '1',
          disableSni: !(queryParams['peer']?.isNotEmpty == true),
          serverName: queryParams['peer'] ?? '',
        ),
        upMbps: int.tryParse(queryParams['upmbps'] ?? '50') ?? 50,
        downMbps: int.tryParse(queryParams['downmbps'] ?? '100') ?? 100,
        disableMtuDiscovery: true,
      );
    } catch (e) {
      return null;
    }
  }

  static Outbound? _parseAnytls(Uri uri) {
    try {
      Map<String, String> queryParams = uri.queryParameters;
      return Outbound(
        type: OutboundType.anytls,
        tag: Uri.decodeComponent(uri.fragment),
        server: uri.host,
        serverPort: uri.port,
        password: uri.userInfo,
        tls: Tls(
          enabled: true,
          insecure: queryParams['allowInsecure'] == '1',
          disableSni: !(queryParams['peer']?.isNotEmpty == true),
          serverName: queryParams['peer'] ?? '',
        ),
      );
    } catch (e) {
      return null;
    }
  }

  static Outbound? _parseTrojan(Uri uri) {
    try {
      Map<String, String> queryParams = uri.queryParameters;
      return Outbound(
        type: OutboundType.trojan,
        tag: Uri.decodeComponent(uri.fragment),
        server: uri.host,
        serverPort: uri.port,
        password: uri.userInfo,
        tls: Tls(
          enabled: true,
          insecure: queryParams['allowInsecure'] == '1',
          disableSni: !(queryParams['peer']?.isNotEmpty == true),
          serverName: queryParams['peer'] ?? '',
        ),
        transport: queryParams['obfs'] == 'websocket'
            ? Transport(type: OutboundTransportType.webSocket)
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  static Outbound? _parseVless(Uri uri) {
    try {
      final Map<String, String> queryParams = uri.queryParameters;
      final String tag = uri.fragment.isNotEmpty
          ? Uri.decodeComponent(uri.fragment)
          : uri.host;

      final String transportType = queryParams['type'] ?? 'tcp';
      Transport? transport;
      if (transportType == OutboundTransportType.webSocket ||
          transportType == 'ws') {
        final Map<String, dynamic> headers = {};
        if (queryParams['host']?.isNotEmpty == true) {
          headers['Host'] = queryParams['host'];
        }
        transport = Transport(
          type: OutboundTransportType.webSocket,
          path: queryParams['path'],
          headers: headers.isNotEmpty ? headers : null,
        );
      } else if (transportType == OutboundTransportType.gRPC ||
          transportType == 'grpc') {
        transport = Transport(type: OutboundTransportType.gRPC);
      } else if (transportType == OutboundTransportType.httpUpgrade ||
          transportType == 'httpupgrade') {
        transport = Transport(type: OutboundTransportType.httpUpgrade);
      }

      final String? security = queryParams['security'];
      final bool tlsEnabled = security == 'tls' || security == 'reality';
      Tls? tls;
      if (tlsEnabled) {
        tls = Tls(
          enabled: true,
          insecure: queryParams['allowInsecure'] == '1',
          disableSni: !(queryParams['sni']?.isNotEmpty == true),
          serverName: queryParams['sni'] ?? '',
          utls: queryParams['fp']?.isNotEmpty == true
              ? Utls(enabled: true, fingerprint: queryParams['fp']!)
              : null,
          reality: security == 'reality'
              ? Reality(
                  enabled: true,
                  publicKey: queryParams['pbk'],
                  shortId: queryParams['sid'],
                  spiderX: queryParams['spx'],
                )
              : null,
        );
      }

      return Outbound(
        type: OutboundType.vless,
        tag: tag,
        server: uri.host,
        serverPort: uri.port,
        uuid: uri.userInfo,
        transport: transport,
        tls: tls,
        security: queryParams['encryption'],
      );
    } catch (e) {
      return null;
    }
  }

}
