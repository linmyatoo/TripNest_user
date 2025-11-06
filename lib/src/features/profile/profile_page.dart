import 'package:flutter/material.dart';
import 'package:tripnest/src/core/services/auth_service.dart';
import 'package:tripnest/src/core/theme/app_colors.dart';
import 'package:tripnest/src/core/widgets/settings_tile.dart';

import 'change_password_page.dart';
import 'help_center_page.dart';
import 'notifications_settings_page.dart';
import 'personal_data_page.dart';
import 'privacy_policy_page.dart';
import 'security_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'User';
  String _email = 'user@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthService.getUserData();
    setState(() {
      _username = userData['username'] ?? 'User';
      _email = userData['email'] ?? 'user@example.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=300&auto=format&fit=crop'),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_username,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(_email,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ])),
            ],
          ),
          const SizedBox(height: 18),
          const Text('General', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PersonalDataPage()))),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.settings,
              label: 'Change Password',
              onTap: () =>
                  Navigator.of(context).pushNamed(ChangePasswordPage.route)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.settings,
              label: 'Notifications',
              onTap: () => Navigator.of(context)
                  .pushNamed(NotificationsSettingsPage.route)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.settings,
              label: 'Security',
              onTap: () => Navigator.of(context).pushNamed(SecurityPage.route)),
          const SizedBox(height: 18),
          const Text('Preferences',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.settings,
              label: 'Legal and Policies',
              onTap: () =>
                  Navigator.of(context).pushNamed(PrivacyPolicyPage.route)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.settings,
              label: 'Help & Support',
              onTap: () =>
                  Navigator.of(context).pushNamed(HelpCenterPage.route)),
          const SizedBox(height: 10),
          SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFEF4444),
            label: 'Logout',
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => const _LogoutConfirmDialog(),
              );
              if (ok == true && mounted) {
                // Perform logout
                await AuthService.logout();

                // Navigate to login and remove all previous routes
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        // ↓ less top padding, a touch more bottom = text sits higher
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
            Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
              const Spacer(),
            ]),
            const SizedBox(height: 6), // was 6

            const Text(
              'Are you sure you want\nto logout?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2, // tighter line height -> visually higher
              ),
            ),
            const SizedBox(height: 8), // was 8

            const Text(
              'Make sure you’ve saved your work or completed any ongoing tasks before logging out.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 2), // was 16

            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Log Out',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
