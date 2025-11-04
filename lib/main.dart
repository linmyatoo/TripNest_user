import 'package:flutter/material.dart';
import 'src/app_router.dart';
import 'src/core/theme/app_colors.dart';

void main() {
  runApp(const TripNestApp());
}

class TripNestApp extends StatelessWidget {
  const TripNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TripNest',
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.primary,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0x1A2563EB),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFFF4F6F8),
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: DialogThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.appShell,
    );
  }
}
