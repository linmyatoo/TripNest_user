import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  static const route = '/forgot-password';
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validation
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    // Basic email validation
    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.forgotPassword(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message from API response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Password reset email sent'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to login page after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forgot Password? 🔒',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "Don't worry! Enter your email and we'll send you a link to reset your password.",
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _emailController,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                prefix:
                    const Icon(Icons.email_outlined, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isLoading ? 'Sending...' : 'Submit',
                onPressed: _isLoading ? null : _handleSubmit,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Remember your password? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
