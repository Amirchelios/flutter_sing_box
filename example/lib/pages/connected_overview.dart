import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sing_box/flutter_sing_box.dart';
import 'package:flutter_sing_box_example/utils/client_providers.dart';
import 'package:flutter_sing_box_example/ui/app_theme.dart';

class ConnectedOverview extends ConsumerStatefulWidget {
  const ConnectedOverview({super.key});

  @override
  ConsumerState<ConnectedOverview> createState() => _ConnectedOverviewState();
}

class _ConnectedOverviewState extends ConsumerState<ConnectedOverview> {
  Profile? _profile;
  SingBox? _singBox;
  final List<GroupItem> _groupItems = [];

  @override
  void initState() {
    super.initState();
    _profile = ProfileManager().getSelectedProfile();
    _initData();
  }

  Future<void> _initData() async {
    final path = _profile?.typed.path;
    if (path?.isNotEmpty != true) return;
    final file = File(path!);
    if (!await file.exists()) return;
    try {
      final map = jsonDecode(await file.readAsString());
      _singBox = SingBox.fromJson(map);
      _groupItems.addAll(
        _singBox!.outbounds
            .where((outbound) => outbound.outbounds?.isNotEmpty == true)
            .map(
              (outbound) => GroupItem(outbound: outbound, isExpanded: false),
            ),
      );

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _selectOutbound(GroupItem groupItem, String outboundTag) {
    try {
      setState(() {
        groupItem.selected = outboundTag;
      });
      ref
          .read(flutterSingBoxProvider)
          .selectOutbound(
            groupTag: groupItem.outbound.tag,
            outboundTag: outboundTag,
          );
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_profile?.name ?? 'Overview')),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              _buildConnectedStatus(),
              const SizedBox(height: 16),
              _buildClashMode(),
              const SizedBox(height: 16),
              _buildGroups(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedStatus() {
    Row buildStatusRow(String text1, String text2) {
      return Row(
        children: [
          Expanded(child: Text(text1)),
          Expanded(child: Text(text2)),
        ],
      );
    }

    final asyncStatus = ref.watch(connectedStreamProvider);
    return asyncStatus.when(
      data: (status) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                buildStatusRow(
                  'Memory: ${status.memory}',
                  'Goroutines: ${status.goroutines}',
                ),
                buildStatusRow(
                  'Connections In: ${status.connectionsIn}',
                  'Connections Out: ${status.connectionsOut}',
                ),
                buildStatusRow(
                  'Uplink: ${status.uplink}',
                  'Downlink: ${status.downlink}',
                ),
                buildStatusRow(
                  'Uplink Total: ${status.uplinkTotal}',
                  'Downlink Total: ${status.downlinkTotal}',
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Connected status: loading...'),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Connected status error: $error'),
        ),
      ),
    );
  }

  Widget _buildClashMode() {
    List<Widget> buildChildren(ClientClashMode clashMode) {
      return clashMode.modes
          .map((mode) {
            final bool isActive = mode == clashMode.currentMode;
            return OutlinedButton(
              onPressed: () {
                ref.read(flutterSingBoxProvider).setClashMode(mode);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: isActive ? AppTheme.teal : Colors.white,
                foregroundColor: isActive ? Colors.white : AppTheme.ink,
                side: BorderSide(
                  color: isActive
                      ? AppTheme.teal
                      : AppTheme.ink.withOpacity(0.2),
                ),
              ),
              child: Text(mode),
            );
          })
          .toList(growable: false);
    }

    final asyncClashMode = ref.watch(clashModeStreamProvider);
    return asyncClashMode.when(
      data: (data) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clash mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: buildChildren(data),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Clash Mode loading...'),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Clash Mode Error: $error'),
        ),
      ),
    );
  }

  Widget _buildGroups() {
    if (_singBox == null) {
      return const SizedBox.shrink();
    }
    ref
        .watch(groupStreamProvider)
        .when(
          data: (clientGroups) {
            for (var clientGroup in clientGroups) {
              final index = _groupItems.indexWhere(
                (item) => item.outbound.tag == clientGroup.tag,
              );
              if (index > -1) {
                _groupItems[index].selected = clientGroup.selected;
                _groupItems[index].isExpanded = clientGroup.isExpand;
                _groupItems[index].items = clientGroup.items ?? [];
              }
            }
          },
          loading: () {},
          error: (error, stack) {},
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ExpansionPanelList(
          elevation: 0,
          expandedHeaderPadding: EdgeInsets.zero,
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _groupItems[index].isExpanded = isExpanded;
            });
            ref
                .read(flutterSingBoxProvider)
                .setGroupExpand(
                  groupTag: _groupItems[index].outbound.tag,
                  isExpand: isExpanded,
                );
          },
          children: _groupItems.map((item) {
            return ExpansionPanel(
              canTapOnHeader: true,
              backgroundColor: Colors.transparent,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.outbound.tag,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.speed),
                            onPressed: () {
                              ref
                                  .read(flutterSingBoxProvider)
                                  .urlTest(groupTag: item.outbound.tag);
                            },
                          ),
                          Text((item.outbound.outbounds?.length ?? 0).toString()),
                        ],
                      ),
                      Row(
                        children: [
                          Text(item.outbound.type),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              item.selected ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.ink.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              body: _buildOutboundItem(item),
              isExpanded: item.isExpanded,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOutboundItem(GroupItem groupItem) {
    final List<Outbound> outbounds = [];
    groupItem.outbound.outbounds?.forEach((outboundTag) {
      final index = _singBox?.outbounds.indexWhere((outbound) {
        return outbound.tag == outboundTag;
      });
      if (index != null && index > -1) {
        final outbound = _singBox?.outbounds[index];
        if (outbound != null) {
          outbounds.add(outbound);
        }
      }
    });
    if (outbounds.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      child: GridView.count(
        childAspectRatio: 3.0,
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: outbounds.map((outbound) {
          final bool isSelected = groupItem.selected == outbound.tag;
          return Card(
            child: InkWell(
              onTap: groupItem.outbound.type != OutboundType.selector
                  ? null
                  : () {
                      _selectOutbound(groupItem, outbound.tag);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                color: isSelected ? AppTheme.teal : Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      outbound.tag,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: isSelected ? Colors.white : AppTheme.ink,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          outbound.type,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: isSelected ? Colors.white : AppTheme.ink,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          groupItem.items
                              .firstWhere(
                                (clientGroupItem) =>
                                    clientGroupItem.tag == outbound.tag,
                                orElse: () => ClientGroupItem(
                                  tag: '',
                                  type: '',
                                  urlTestTime: 0,
                                  urlTestDelay: 0,
                                ),
                              )
                              .urlTestDelay
                              .toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.ink.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GroupItem {
  Outbound outbound;
  bool isExpanded;
  String? selected;
  List<ClientGroupItem> items;
  GroupItem({
    required this.outbound,
    required this.isExpanded,
    this.selected,
    this.items = const [],
  });
}
