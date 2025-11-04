import 'package:flutter/material.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class SignUpPage extends StatelessWidget {
  static const route = '/signup';
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Your Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text("Join us today and unlock endless possibilities. It's quick, easy, and just a step away!",
                  style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 22),

              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your name',
                controller: name,
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.person_outline),
              ),

              const SizedBox(height: 16),
              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your number',
                controller: phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefix: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('assets/images/flag_th.png', width: 22, height: 22),
                    const SizedBox(width: 8),
                    const Text('+66', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const VerticalDivider(width: 1.0, thickness: 1.0),
                    const SizedBox(width: 4),
                  ]),
                ),
              ),

              const SizedBox(height: 16),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your email',
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.email_outlined),
              ),

              const SizedBox(height: 16),
              const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your password',
                controller: password,
                obscure: true,
                textInputAction: TextInputAction.done,
                prefix: const Icon(Icons.lock_outline),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.remove_red_eye_outlined),
                ),
              ),

              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Sign Up',
                onPressed: () {
                  showDialog(context: context, builder: (_) => const _SignUpSuccessDialog());
                },
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 22, height: 22,
                    child: Checkbox(value: false, onChanged: (_) {})),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Wrap(
                      children: [
                        Text('By creating an account, you agree to our '),
                        _Blue('Terms and Conditions'),
                        Text(' and '),
                        _Blue('Privacy Notice'),
                        Text('.'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? '),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const _Blue('Sign In'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blue extends StatelessWidget {
  final String text;
  const _Blue(this.text);

  @override
  Widget build(BuildContext context) {
    return const Text('Sign In', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600));
  }
}

class _SignUpSuccessDialog extends StatelessWidget {
  const _SignUpSuccessDialog();

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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Blue check with soft halo
          Container(
            width: 86, height: 86,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDDEBFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB), // AppColors.primary
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your registration is successful!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            "Thanks for joining us\nLet's make memories together",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),

          // Full-width primary button (rounded, like the mock)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Login Now', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
