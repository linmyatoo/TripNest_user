import 'package:flutter/material.dart';
import '../../core/widgets/primary_button.dart';

class NotificationsSettingsPage extends StatefulWidget {
  static const route = '/notification-settings';
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool notifications = true;
  bool sound = false;
  bool vibrate = false;
  bool offers = true;
  bool payments = false;
  bool cashback = false;
  bool updates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Notifications')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(children: [
          _row('Notifications', notifications, (v) => setState(() => notifications = v)),
          _row('Sound', sound, (v) => setState(() => sound = v)),
          _row('Vibrate', vibrate, (v) => setState(() => vibrate = v)),
          _row('Special Offers', offers, (v) => setState(() => offers = v)),
          _row('Payments', payments, (v) => setState(() => payments = v)),
          _row('Cashback', cashback, (v) => setState(() => cashback = v)),
          _row('App Updates', updates, (v) => setState(() => updates = v)),
          const Spacer(),
          PrimaryButton(label: 'Save', onPressed: () {}),
        ]),
      ),
    );
  }

  Widget _row(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      height: 54,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}
