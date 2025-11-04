import 'package:flutter/material.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class ChangePasswordPage extends StatelessWidget {
  static const route = '/change-password';
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Current Password', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          AppTextField(hint: 'Enter Your Password', obscure: true),
          SizedBox(height: 16),
          Text('New Password', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          AppTextField(hint: 'Enter Your new Password', obscure: true),
          SizedBox(height: 16),
          Text('New Password', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          AppTextField(hint: 'Enter Your new Password', obscure: true),
          const SizedBox(height: 24),
          PrimaryButton(
            // Keeping the label to match your Figma text exactly
            label: 'Save Changes',
            onPressed: () {
              // TODO: add validation / API call here if needed
              Navigator.pop(context); // returns to Profile page
            },
          ),
        ],
      ),
    );
  }
}
