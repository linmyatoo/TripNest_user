import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/notification_settings_service.dart';
import '../../core/widgets/primary_button.dart';

class NotificationsSettingsPage extends StatefulWidget {
  static const route = '/notification-settings';
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _notifications = true;
  bool _sound = true;
  bool _vibrate = true;
  bool _offers = true;
  bool _payments = true;
  bool _cashback = true;
  bool _updates = true;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final settings = await NotificationSettingsService.getAllSettings();

    if (mounted) {
      setState(() {
        _notifications = settings['notifications'] ?? true;
        _sound = settings['sound'] ?? true;
        _vibrate = settings['vibrate'] ?? true;
        _offers = settings['specialOffers'] ?? true;
        _payments = settings['payments'] ?? true;
        _cashback = settings['cashback'] ?? true;
        _updates = settings['appUpdates'] ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await NotificationSettingsService.saveAllSettings(
        notifications: _notifications,
        sound: _sound,
        vibrate: _vibrate,
        specialOffers: _offers,
        payments: _payments,
        cashback: _cashback,
        appUpdates: _updates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _onNotificationsChanged(bool value) {
    setState(() {
      _notifications = value;
      // If notifications are disabled, disable sound and vibrate
      if (!value) {
        _sound = false;
        _vibrate = false;
      }
    });
  }

  void _onSoundChanged(bool value) {
    setState(() => _sound = value);
    // Play a test sound if enabling
    if (value && _notifications) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _onVibrateChanged(bool value) {
    setState(() => _vibrate = value);
    // Test vibration if enabling
    if (value && _notifications) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(children: [
                _SwitchTile(
                  title: 'Notifications',
                  subtitle: 'Enable or disable all notifications',
                  value: _notifications,
                  onChanged: _onNotificationsChanged,
                ),
                _SwitchTile(
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _sound,
                  onChanged: _onSoundChanged,
                  enabled: _notifications,
                ),
                _SwitchTile(
                  title: 'Vibrate',
                  subtitle: 'Vibrate for notifications',
                  value: _vibrate,
                  onChanged: _onVibrateChanged,
                  enabled: _notifications,
                ),
                const Divider(height: 24),
                _SwitchTile(
                  title: 'Special Offers',
                  subtitle: 'Get notified about deals and discounts',
                  value: _offers,
                  onChanged: (v) => setState(() => _offers = v),
                  enabled: _notifications,
                ),
                _SwitchTile(
                  title: 'Payments',
                  subtitle: 'Payment confirmations and updates',
                  value: _payments,
                  onChanged: (v) => setState(() => _payments = v),
                  enabled: _notifications,
                ),
                _SwitchTile(
                  title: 'Cashback',
                  subtitle: 'Cashback rewards and earnings',
                  value: _cashback,
                  onChanged: (v) => setState(() => _cashback = v),
                  enabled: _notifications,
                ),
                _SwitchTile(
                  title: 'App Updates',
                  subtitle: 'New features and improvements',
                  value: _updates,
                  onChanged: (v) => setState(() => _updates = v),
                  enabled: _notifications,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
