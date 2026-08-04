# TripNest

TripNest is a Flutter-based mobile app for discovering, booking, and managing travel experiences and events. The app includes onboarding, event browsing, favorites, bookings, payments, notifications, and an AI chatbot assistant.

## Features

- Onboarding and authentication flows
- Event discovery and browsing
- Favorites and booking management
- Payment flow and profile settings
- Notifications and messaging support
- AI chatbot assistant for travel help

## Project Structure

- lib/main.dart: app entry point
- lib/src/app_router.dart: route definitions
- lib/src/app_shell.dart: bottom navigation shell
- lib/src/features/: feature-based screens and logic
- lib/src/core/: shared services, theme, and utilities
- lib/src/models/: app data models
- lib/src/widgets/: reusable UI components

## Tech Stack

- Flutter
- Dart
- http for network requests
- shared_preferences for local persistence
- local_auth for biometric authentication
- flutter_local_notifications for notifications

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or newer
- A supported emulator or physical device

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Lint and test

```bash
flutter analyze
flutter test
```

## Notes

- Assets are stored under assets/images and assets/icons.
- The app uses feature-based organization under lib/src/features for maintainability.
- If you add new assets, make sure they are declared in pubspec.yaml.
