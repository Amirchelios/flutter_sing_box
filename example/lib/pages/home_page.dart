import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sing_box/flutter_sing_box.dart';
import 'package:flutter_sing_box_example/pages/connected_overview.dart';
import 'package:flutter_sing_box_example/utils/client_providers.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/snackbar_util.dart';
import 'config_profiles.dart';
import '../ui/app_theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _flutterSingBoxPlugin = FlutterSingBox();
  final List<Profile> _profiles = [];
  Profile? _selectedProfile;


  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    _selectedProfile = ProfileManager().getSelectedProfile();
    _profiles.clear();
    _profiles.addAll(ProfileManager().getProfiles());
    if (!mounted) return;
    setState(() {

    });
  }

  Future<void> _switchProfile(int profileId) async {
    ProfileManager().setSelectedProfile(profileId);
    _loadProfiles();
    if (ref.read(proxyStateStreamProvider).value == ProxyState.started) {
      try {
        await Future.delayed(const Duration(milliseconds: 3000));
        await ref.read(flutterSingBoxProvider).stopVpn();
        debugPrint('stopVpn');
        await Future.delayed(const Duration(milliseconds: 1500));
        await ref.read(flutterSingBoxProvider).startVpn();
        debugPrint('startVpn');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> _startVpn() async {
    try {
      await requestPostNotificationPermission();
      await ref.read(flutterSingBoxProvider).startVpn();
    } on PlatformException catch (e) {
      String errorMessage = '启动VPN失败';
      if (e.code == 'NO_ACTIVITY') {
        errorMessage = '无法获取Activity实例';
      } else if (e.code == 'VPN_PERMISSION_DENIED') {
        errorMessage = '用户拒绝了VPN权限';
      } else if (e.code == 'VPN_ERROR') {
        errorMessage = e.message ?? '启动VPN服务失败';
      }
      SnackbarUtil.showError(errorMessage);
    } catch (e) {
      SnackbarUtil.showError('未知错误: ${e.toString()}');
    }
  }

  Future<bool> requestPostNotificationPermission() async {
    try {
      var status = await Permission.notification.request();
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        SnackbarUtil.showError('用户拒绝了权限（可再次请求）');
        return false;
      } else if (status.isPermanentlyDenied) {
        SnackbarUtil.showError('权限被永久拒绝，需引导用户去设置中开启');
        openAppSettings(); // 跳转到应用设置页面
        return false;
      }
    } catch (e) {
      SnackbarUtil.showError('获取权限失败: ${e.toString()}');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SingBox Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Profiles',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfigProfiles()),
              );
              _loadProfiles();
            },
          ),
        ],
      ),
      body: AppBackground(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildActionRow(),
          const SizedBox(height: 16),
          Expanded(child: _buildProfilesSection()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final asyncProxyState = ref.watch(proxyStateStreamProvider);
    return asyncProxyState.when(
      data: (state) {
        final isRunning = state == ProxyState.started || state == ProxyState.starting;
        final statusText = isRunning ? 'Running' : 'Stopped';
        final statusColor = isRunning ? AppTheme.teal : AppTheme.coral;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    _buildOverviewButton(isRunning),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedProfile?.name ?? 'No profile selected',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedProfile == null
                      ? 'Add a profile to start routing traffic.'
                      : 'Tap a profile below to switch.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.ink.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stack) {
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _buildActionRow() {
    final asyncProxyState = ref.watch(proxyStateStreamProvider);
    return asyncProxyState.when(
      data: (state) {
        final isRunning = state == ProxyState.started || state == ProxyState.starting;
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (isRunning) {
                    await FlutterSingBox().stopVpn();
                  } else {
                    await _startVpn();
                  }
                },
                icon: Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(isRunning ? 'Stop' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConfigProfiles()),
                  );
                  _loadProfiles();
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.ink,
                  side: BorderSide(color: AppTheme.ink.withOpacity(0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stack) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _buildProfilesSection() {
    if (_profiles.isEmpty) {
      return Card(
        child: Center(
          child: Text(
            'No profiles yet. Add one to begin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _profiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildProfileItem(_profiles[index]);
      },
    );
  }

  Widget _buildProfileItem(Profile profile) {
    final bool isSelected = _selectedProfile?.id == profile.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppTheme.teal : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          title: Text(
            profile.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            'Updated: ${DateTime.fromMillisecondsSinceEpoch(profile.typed.lastUpdated)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.ink.withOpacity(0.6),
                ),
          ),
          trailing: IconButton(
            icon: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.teal : AppTheme.ink.withOpacity(0.4),
            ),
            onPressed: () {
              if (!isSelected) {
                _switchProfile(profile.id);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewButton(bool isRunning) {
    if (!isRunning) {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ConnectedOverview()),
        );
      },
      icon: const Icon(Icons.data_usage),
      label: const Text('Overview'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.ink,
        side: BorderSide(color: AppTheme.ink.withOpacity(0.15)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildLogs() {
    return StreamBuilder<List<String>>(
      stream: _flutterSingBoxPlugin.logStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final str = snapshot.data?.first ?? 'EMPTY!';
          return Text(str);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
