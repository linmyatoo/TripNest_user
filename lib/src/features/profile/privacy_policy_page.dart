import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  static const route = '/privacy-policy';
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Privacy & Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          SizedBox(height: 6),
          Text('Effective Date: December 20, 2024', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 14),
          _Section(
            title: '1. Information Collection',
            body:
                'We collect essential information to enhance your experience. This includes details you provide directly, such as account data, as well as information gathered through usage analytics and cookies.',
          ),
          _Section(
            title: '2. Information Usage',
            body:
                'The information collected is used to improve our services, provide personalized recommendations, and ensure a seamless experience. We do not share your data without your explicit consent.',
          ),
          _Section(
            title: '3. Information Setting',
            body:
                'You have full control over your data. Manage your privacy preferences, update personal details, and customize your settings to match your needs.',
          ),
          _Section(
            title: '4. Security Measures',
            body:
                'We prioritize your data’s safety with advanced security protocols, encryption methods, and regular audits to protect against unauthorized access or breaches.',
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title, body;
  const _Section({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(color: Color(0xFF6B7280))),
      ]),
    );
  }
}
