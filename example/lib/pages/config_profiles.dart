import 'package:flutter/material.dart';
import 'package:flutter_sing_box/flutter_sing_box.dart';
import 'package:flutter_sing_box_example/pages/new_remote_profile.dart';
import 'package:flutter_sing_box_example/ui/app_theme.dart';

class ConfigProfiles extends StatefulWidget {
  const ConfigProfiles({super.key});

  @override
  State<ConfigProfiles> createState() => _ConfigProfilesState();
}

class _ConfigProfilesState extends State<ConfigProfiles> {
  final ScrollController _scrollController = ScrollController();
  final List<Profile> profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    profiles
      ..clear()
      ..addAll(ProfileManager().getProfiles());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedProfile = ProfileManager().getSelectedProfile();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  title: const Text('Import a profile'),
                  subtitle: const Text('Add a subscription URL or a single link.'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (builder) {
                        return const NewRemoteProfile();
                      }),
                    );
                    _loadProfiles();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: profiles.isEmpty
                    ? Center(
                        child: Text(
                          'No profiles yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          final bool isSelected = selectedProfile?.id == profile.id;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.teal
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(
                                  profile.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Updated: ${DateTime.fromMillisecondsSinceEpoch(profile.typed.lastUpdated)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.ink.withOpacity(0.6),
                                      ),
                                ),
                                leading: Icon(
                                  isSelected
                                      ? Icons.verified_rounded
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppTheme.teal
                                      : AppTheme.ink.withOpacity(0.4),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    ProfileManager().deleteProfile(profile.id);
                                    _loadProfiles();
                                  },
                                ),
                                onTap: () {
                                  ProfileManager()
                                      .setSelectedProfile(profile.id);
                                  _loadProfiles();
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
