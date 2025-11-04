import 'package:flutter/material.dart';
import '../../core/widgets/primary_button.dart';

class SecurityPage extends StatefulWidget {
  static const route = '/security';
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool remember = true;
  bool faceId = true;
  bool bioId = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Security')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(children: [
          _SwitchTile(title: 'Remember Password', value: remember, onChanged: (v) => setState(() => remember = v)),
          _SwitchTile(title: 'Face ID', value: faceId, onChanged: (v) => setState(() => faceId = v)),
          _SwitchTile(title: 'Biometric ID', value: bioId, onChanged: (v) => setState(() => bioId = v)),
          const _ChevronTile(title: 'Google Authenticator'),
          const Spacer(),
          PrimaryButton(label: 'Save', onPressed: () {}),
        ]),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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

class _ChevronTile extends StatelessWidget {
  final String title;
  const _ChevronTile({required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12)),
      child: Row(children: const [
        Expanded(child: Text('Google Authenticator', style: TextStyle(fontWeight: FontWeight.w600))),
        Icon(Icons.chevron_right_rounded),
      ]),
    );
  }
}
