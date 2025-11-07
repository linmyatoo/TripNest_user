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
      await AuthService.forgotPassword(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _ForgotPasswordSuccessDialog(
            email: email,
          ),
        );
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

class _ForgotPasswordSuccessDialog extends StatelessWidget {
  final String email;
  const _ForgotPasswordSuccessDialog({required this.email});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Email icon with gradient background
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDDEBFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Check Your Email',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Your password reset link has been sent to\n$email',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
