import 'package:flutter/material.dart';
import 'package:flutter_sing_box/flutter_sing_box.dart';
import 'package:flutter_sing_box_example/ui/app_theme.dart';

class NewRemoteProfile extends StatefulWidget {
  const NewRemoteProfile({super.key});

  @override
  State<NewRemoteProfile> createState() => _NewRemoteProfileState();
}

class _NewRemoteProfileState extends State<NewRemoteProfile> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _link;
  bool _isSaving = false;

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _formKey.currentState!.save();
    if (_link == null) return;

    setState(() => _isSaving = true);
    try {
      final Uri? uri = Uri.tryParse(_link!.trim());
      if (_isInlineLink(uri)) {
        await ProfileService().importProfileFromContent(
          content: _link!.trim(),
          name: _name,
        );
      } else {
        final uriSafe = Uri.parse(_link!.trim());
        await ProfileService().importProfile(
          subscribeLink: uriSafe,
          name: _name,
          autoUpdateInterval: 1440,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isInlineLink(Uri? uri) {
    if (uri == null) return false;
    const inlineSchemes = {
      'vless',
      'vmess',
      'trojan',
      'ss',
      'ssr',
      'hysteria',
      'hysteria2',
      'anytls',
    };
    return inlineSchemes.contains(uri.scheme.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Profile'),
      ),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bring a config into SingBox.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Paste a subscription URL or a single VLESS link.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.ink.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Profile name (optional)',
                      ),
                      onSaved: (value) => _name = value?.trim(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Subscription URL or VLESS link',
                        hintText: 'https://... or vless://uuid@host:port',
                      ),
                      minLines: 1,
                      maxLines: 4,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Enter a link to continue.';
                        }
                        final Uri? uri = Uri.tryParse(value!.trim());
                        if (uri == null || uri.scheme.isEmpty) {
                          return 'Invalid link format.';
                        }
                        return null;
                      },
                      onSaved: (value) => _link = value?.trim(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.coal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
