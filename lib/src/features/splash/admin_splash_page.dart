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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF60A5FA), // light blue
              Color(0xFF3B82F6), // medium blue
              Color(0xFF6366F1), // purple blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'TripNest',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Wait a moment...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
// ...existing code...
}
