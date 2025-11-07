import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/sign_up_page.dart';
import 'features/booking/review_page.dart';
import 'features/chatbot/chatbot_page.dart';
import 'features/details/event_detail_page.dart';
import 'features/notifications/notification_feed_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/payment/payment_page.dart';
import 'features/profile/change_password_page.dart';
import 'features/profile/help_center_page.dart';
import 'features/profile/notifications_settings_page.dart';
import 'features/profile/personal_data_page.dart';
import 'features/profile/privacy_policy_page.dart';
import 'features/profile/security_page.dart';
import 'features/search/search_page.dart';
import 'features/search/search_results_page.dart';
import 'features/splash/admin_splash_page.dart';
import 'models/event.dart'; // 👈 for (settings.arguments as Event)

class AppRoutes {
  static const appShell = '/app';
  static const eventDetails = '/event';
  static const payment = '/payment';
  static const search = '/search';
  static const searchResults = '/search_results';
  static const review = '/review';
  static const chatbot = '/chatbot';
}

class AppRouter {
  static Route<dynamic> _adaptive(Widget page, {RouteSettings? settings}) {
    final platform = kIsWeb ? TargetPlatform.android : defaultTargetPlatform;
    if (platform == TargetPlatform.iOS) {
      return CupertinoPageRoute(builder: (_) => page, settings: settings);
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AdminSplashPage.route:
        return _adaptive(const AdminSplashPage(), settings: settings);
      case OnboardingPage.route:
        return _adaptive(const OnboardingPage(), settings: settings);
      case LoginPage.route:
        return _adaptive(const LoginPage(), settings: settings);
      case SignUpPage.route:
        return _adaptive(const SignUpPage(), settings: settings);
      case ForgotPasswordPage.route:
        return _adaptive(const ForgotPasswordPage(), settings: settings);
      case NotificationFeedPage.route:
        return _adaptive(const NotificationFeedPage(), settings: settings);

      case PersonalDataPage.route:
        return _adaptive(const PersonalDataPage(), settings: settings);
      case ChangePasswordPage.route:
        return _adaptive(const ChangePasswordPage(), settings: settings);
      case NotificationsSettingsPage.route:
        return _adaptive(const NotificationsSettingsPage(), settings: settings);
      case SecurityPage.route:
        return _adaptive(const SecurityPage(), settings: settings);
      case PrivacyPolicyPage.route:
        return _adaptive(const PrivacyPolicyPage(), settings: settings);
      case HelpCenterPage.route:
        return _adaptive(const HelpCenterPage(), settings: settings);

      case AppRoutes.appShell:
        // If your AppShell has no initialIndex param, keep this:
        return _adaptive(const AppShell(), settings: settings);
      // If you added it, use:
      // final initialIndex = (settings.arguments as int?) ?? 0;
      // return _adaptive(AppShell(initialIndex: initialIndex), settings: settings);

      case AppRoutes.eventDetails:
        return _adaptive(EventDetailPage(event: settings.arguments as Event),
            settings: settings);

      case AppRoutes.payment:
        return _adaptive(PaymentPage(event: settings.arguments as Event),
            settings: settings);

      case AppRoutes.search:
        return _adaptive(const SearchPage(), settings: settings);

      case AppRoutes.searchResults:
        // SearchResultsPage accepts a generic Object? for query; forward the raw arguments
        return _adaptive(SearchResultsPage(query: settings.arguments),
            settings: settings);

      case AppRoutes.review:
        return _adaptive(ReviewPage(eventId: settings.arguments as String),
            settings: settings);

      case AppRoutes.chatbot:
        return _adaptive(const ChatbotPage(), settings: settings);

      default:
        return _adaptive(
            const Scaffold(body: Center(child: Text('Route not found'))));
    }
  }
}
