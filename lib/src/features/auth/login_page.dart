import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  static const route = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validation
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Login successful'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to app
        Navigator.pushReplacementNamed(context, '/app');
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
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome Back! 👋',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text("Glad to have you here again. Let's get started!",
                  style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 22),
              const Text('Email',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              const Text('Password',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your password',
                controller: _passwordController,
                obscure: true,
                textInputAction: TextInputAction.done,
                prefix: const Icon(Icons.lock_outline),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.remove_red_eye_outlined),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {},
                  child: const Text('Forgot Password?',
                      style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _isLoading ? 'Signing In...' : 'Sign In',
                onPressed: _isLoading ? null : _handleLogin,
              ),
              const SizedBox(height: 18),
              Row(children: const [
                Expanded(child: Divider()),
                SizedBox(width: 12),
                Text('Or continue with'),
                SizedBox(width: 12),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Social('assets/icons/google.png'),
                  SizedBox(width: 16),
                  _Social('assets/icons/apple.png'),
                  SizedBox(width: 16),
                  _Social('assets/icons/facebook.png'),
                ],
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/signup'),
                  child: const Text('Sign Up',
                      style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Social extends StatelessWidget {
  final String path;
  const _Social(this.path);

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Center(child: Image.asset(path, width: 22, height: 22)),
      ),
    );
  }
}
