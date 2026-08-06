import 'package:flutter/material.dart';
import '../../core/services/security_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';

class SecurityPage extends StatefulWidget {
  static const route = '/security';
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _remember = false;
  bool _faceId = false;
  bool _bioId = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _faceIdAvailable = false;
  bool _fingerprintAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final remember = await SecurityService.isRememberPasswordEnabled();
    final faceId = await SecurityService.isFaceIdEnabled();
    final bioId = await SecurityService.isBiometricEnabled();
    final faceIdAvailable = await SecurityService.isFaceIdAvailable();
    final fingerprintAvailable = await SecurityService.isFingerprintAvailable();

    if (mounted) {
      setState(() {
        _remember = remember;
        _faceId = faceId;
        _bioId = bioId;
        _faceIdAvailable = faceIdAvailable;
        _fingerprintAvailable = fingerprintAvailable;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await SecurityService.setRememberPassword(_remember);
      await SecurityService.setFaceIdEnabled(_faceId);
      await SecurityService.setBiometricEnabled(_bioId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security settings saved'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to profile page
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onFaceIdChanged(bool value) {
    if (value && !_faceIdAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face ID is not available on this device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If enabling Face ID, also enable remember password
    if (value && !_remember) {
      setState(() {
        _remember = true;
        _faceId = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remember Password enabled for Face ID login'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      setState(() => _faceId = value);
    }
  }

  void _onBiometricChanged(bool value) {
    if (value && !_fingerprintAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Biometric authentication is not available on this device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If enabling biometric, also enable remember password
    if (value && !_remember) {
      setState(() {
        _remember = true;
        _bioId = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remember Password enabled for biometric login'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      setState(() => _bioId = value);
    }
  }

  void _onRememberChanged(bool value) {
    setState(() {
      _remember = value;
      // If disabling remember password, also disable biometric options
      if (!value) {
        _faceId = false;
        _bioId = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(leading: const BackButton(), title: const Text('Security')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(children: [
                _SwitchTile(
                  title: 'Remember Password',
                  subtitle: 'Save your login credentials',
                  value: _remember,
                  onChanged: _onRememberChanged,
                ),
                _SwitchTile(
                  title: 'Face ID',
                  subtitle: _faceIdAvailable
                      ? 'Use Face ID to login quickly'
                      : 'Not available on this device',
                  value: _faceId,
                  onChanged: _onFaceIdChanged,
                  enabled: _faceIdAvailable,
                ),
                _SwitchTile(
                  title: 'Biometric ID',
                  subtitle: _fingerprintAvailable
                      ? 'Use fingerprint to login quickly'
                      : 'Not available on this device',
                  value: _bioId,
                  onChanged: _onBiometricChanged,
                  enabled: _fingerprintAvailable,
                ),
                _ChevronTile(
                  title: 'Google Authenticator',
                  // No TOTP enrolment exists yet; the row used to have no
                  // handler at all, so tapping it did nothing silently.
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Authenticator app support is coming soon.'),
                    ),
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: _isSaving ? 'Saving...' : 'Save',
                  onPressed: _isSaving ? null : _saveSettings,
                ),
              ]),
            ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.black : Colors.grey,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ]),
    );
  }
}

class _ChevronTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _ChevronTile({required this.title, this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 54,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: enabled ? null : AppColors.muted))),
          Icon(Icons.chevron_right_rounded,
              color: enabled ? null : AppColors.muted),
        ]),
      ),
    );
  }
}
