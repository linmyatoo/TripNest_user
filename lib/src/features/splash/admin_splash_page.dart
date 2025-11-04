import 'package:flutter/material.dart';

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
    Future.delayed(const Duration(milliseconds: 900), () {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    });
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
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              SizedBox(height: 8),
              Text('Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
// ...existing code...
}
