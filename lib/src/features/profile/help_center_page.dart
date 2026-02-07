import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  static const route = '/help-center';
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(leading: const BackButton(), title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded),
            ),
          ]),
          const SizedBox(height: 16),
          const _FAQTile(
            question: 'How do I reset my password?',
            answer:
                'You can reach your password options from Profile → Change Password, then follow the steps to create a new password.',
            expanded: true,
          ),
          const _FAQTile(
            question: 'How do I contact support?',
            answer:
                'You can contact our support team via email at support@tripnest.com or through the Help & Support section in your Profile settings.',
          ),
          const _FAQTile(
            question: 'How can I update my information?',
            answer:
                'Go to Profile → Personal Data to update your name, email, phone number, date of birth, gender, and other personal information.',
          ),
          const _FAQTile(
            question: 'How do I report an issue?',
            answer:
                'To report an issue, please contact our support team at support@tripnest.com with a description of the problem and any relevant screenshots.',
          ),
          const _FAQTile(
            question: 'How do I manage notifications?',
            answer:
                'You can manage your notification preferences by going to Profile → Notifications. From there, you can enable or disable notifications, sound, vibration, and specific notification types.',
          ),
        ],
      ),
    );
  }
}

class _FAQTile extends StatelessWidget {
  final String question, answer;
  final bool expanded;
  const _FAQTile(
      {required this.question, required this.answer, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title:
            Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Text(answer, style: const TextStyle(color: Color(0xFF6B7280)))
        ],
      ),
    );
  }
}
