import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

class AdminSplashPage extends StatefulWidget {
  static const route = '/';
  const AdminSplashPage({super.key});

  @override
  State<AdminSplashPage> createState() => _AdminSplashPageState();
}

class _AdminSplashPageState extends State<AdminSplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    // Check if user is already logged in
    final isLoggedIn = await AuthService.isLoggedIn();

    if (isLoggedIn) {
      // User is logged in, go to app
      Navigator.of(context).pushReplacementNamed('/app');
    } else {
      // User is not logged in, go to onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'TripNest',
                style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              SizedBox(height: 8),
              Text('Admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
// ...existing code...
}
