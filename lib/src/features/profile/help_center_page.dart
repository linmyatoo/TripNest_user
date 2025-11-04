import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  static const route = '/help-center';
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Ink(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded),
            ),
          ]),
          const SizedBox(height: 16),
          const _FAQTile(
            question: 'How do I reset my password?',
            answer: 'You can reach your password options from Settings → Change Password, then follow the steps to create a new password.',
            expanded: true,
          ),
          const _ArrowFAQ(question: 'How do I contact support?'),
          const _ArrowFAQ(question: 'How can I update my information?'),
          const _ArrowFAQ(question: 'How do I report an issue?'),
          const _ArrowFAQ(question: 'How do I manage notifications?'),
        ],
      ),
    );
  }
}

class _FAQTile extends StatelessWidget {
  final String question, answer;
  final bool expanded;
  const _FAQTile({required this.question, required this.answer, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [Text(answer, style: const TextStyle(color: Color(0xFF6B7280)))],
      ),
    );
  }
}

class _ArrowFAQ extends StatelessWidget {
  final String question;
  const _ArrowFAQ({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Text(question, style: const TextStyle(fontWeight: FontWeight.w600))),
        const Icon(Icons.chevron_right_rounded),
      ]),
    );
  }
}
