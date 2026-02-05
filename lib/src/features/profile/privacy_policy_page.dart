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
          Text('Effective Date: February 5, 2026', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            'Welcome to TripNest. Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our travel and event booking platform.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          SizedBox(height: 14),
          _Section(
            title: '1. Information We Collect',
            body:
                'We collect information you provide directly, including:\n\n'
                '• Account Information: Name, email address, phone number, date of birth, gender, and profile picture when you create an account.\n\n'
                '• Booking Information: Details about events you book, travel preferences, payment information, and booking history.\n\n'
                '• Communication Data: Messages you send through our platform and your interactions with event organizers.\n\n'
                '• Device Information: Device type, operating system, and app usage analytics to improve our services.',
          ),
          _Section(
            title: '2. How We Use Your Information',
            body:
                'Your information is used to:\n\n'
                '• Process and manage your event bookings and reservations.\n\n'
                '• Personalize your experience with recommended events and destinations.\n\n'
                '• Send booking confirmations, updates, and important notifications.\n\n'
                '• Provide customer support and respond to your inquiries.\n\n'
                '• Improve our app features and user experience.\n\n'
                '• Maintain the security and integrity of our platform.',
          ),
          _Section(
            title: '3. Information Sharing',
            body:
                'We may share your information with:\n\n'
                '• Event Organizers: To facilitate your bookings and provide services you request.\n\n'
                '• Payment Processors: To securely process your transactions.\n\n'
                '• Service Providers: Third parties who assist us in operating our platform.\n\n'
                'We do NOT sell your personal information to third parties for marketing purposes.',
          ),
          _Section(
            title: '4. Data Storage & Security',
            body:
                'We implement industry-standard security measures to protect your data:\n\n'
                '• Encrypted data transmission using SSL/TLS protocols.\n\n'
                '• Secure authentication with token-based access.\n\n'
                '• Regular security audits and vulnerability assessments.\n\n'
                '• Restricted access to personal data on a need-to-know basis.\n\n'
                'Your data is stored on secure servers and retained only as long as necessary to provide our services.',
          ),
          _Section(
            title: '5. Your Rights & Choices',
            body:
                'You have the right to:\n\n'
                '• Access and Update: View and edit your personal information in your profile settings.\n\n'
                '• Delete Account: Request deletion of your account and associated data.\n\n'
                '• Notification Preferences: Control what notifications you receive.\n\n'
                '• Data Portability: Request a copy of your personal data.\n\n'
                '• Withdraw Consent: Opt out of certain data processing activities.',
          ),
          _Section(
            title: '6. Cookies & Tracking',
            body:
                'We use cookies and similar technologies to:\n\n'
                '• Remember your login sessions and preferences.\n\n'
                '• Analyze app usage and improve performance.\n\n'
                '• Provide personalized content and recommendations.\n\n'
                'You can manage cookie preferences through your device settings.',
          ),
          _Section(
            title: '7. Third-Party Services',
            body:
                'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these external sites. We encourage you to review their privacy policies before providing any personal information.',
          ),
          _Section(
            title: '8. Children\'s Privacy',
            body:
                'TripNest is not intended for users under 13 years of age. We do not knowingly collect personal information from children. If we discover that a child has provided us with personal data, we will delete it promptly.',
          ),
          _Section(
            title: '9. Changes to This Policy',
            body:
                'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or via email. Your continued use of TripNest after changes constitutes acceptance of the updated policy.',
          ),
          _Section(
            title: '10. Contact Us',
            body:
                'If you have questions or concerns about this Privacy Policy or our data practices, please contact us at:\n\n'
                '• Email: privacy@tripnest.com\n\n'
                '• Support: Available through the Help & Support section in the app.',
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
