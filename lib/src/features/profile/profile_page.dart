import 'package:flutter/material.dart';
import 'package:tripnest/src/core/services/auth_service.dart';
import 'package:tripnest/src/core/services/security_service.dart';
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
  String? _profileImage;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Fetch profile using GET /api/profile/me
      final response = await AuthService.getProfileMe();
      if (!mounted) return;

      // API returns: {userId, fullName, phone, gender, profilePictureUrl, email}
      final user = response['data'] ?? response['user'] ?? response;

      // Extract values using the actual API field names
      final name = user['fullName'] ?? user['name'] ?? user['username'];
      String? image =
          user['profilePictureUrl'] ?? user['profileImage'] ?? user['avatar'];

      // Filter out placeholder URLs
      if (image != null &&
          (image.contains('placeholder') ||
              image.contains('via.placeholder'))) {
        image = null;
      }

      // Get email from API response
      final email = user['email'];

      setState(() {
        _username = (name != null && name != 'Not Set') ? name : 'User';
        _email = email ?? 'user@example.com';
        _profileImage = image;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      // Fallback to local storage data if API fails
      try {
        final userData = await AuthService.getUserData();
        if (!mounted) return;
        setState(() {
          _username = userData['name'] ?? userData['username'] ?? 'User';
          _email = userData['email'] ?? 'user@example.com';
          _isLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _profileImage != null && _profileImage!.isNotEmpty
                          ? NetworkImage(_profileImage!)
                          : const AssetImage('assets/images/avatar_jacob.jpg')
                              as ImageProvider,
                  onBackgroundImageError: (_, __) {
                    // Handle image load error silently
                  },
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
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ])),
              ],
            ),
          const SizedBox(height: 18),
          const Text('General', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              onTap: () async {
                final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (_) => const PersonalDataPage()));
                // Refresh profile data if it was updated
                if (updated == true && mounted) {
                  _loadUserData();
                }
              }),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.settings,
              label: 'Change Password',
              onTap: () =>
                  Navigator.of(context).pushNamed(ChangePasswordPage.route)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => Navigator.of(context)
                  .pushNamed(NotificationsSettingsPage.route)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.security_outlined,
              label: 'Security',
              onTap: () => Navigator.of(context).pushNamed(SecurityPage.route)),
          const SizedBox(height: 18),
          const Text('Preferences',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.policy_outlined,
              label: 'Legal and Policies',
              onTap: () =>
                  Navigator.of(context).pushNamed(PrivacyPolicyPage.route)),
          const SizedBox(height: 10),
          SettingsTile(
              icon: Icons.help_outline,
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

                // Only clear saved credentials if Remember Password is disabled
                final rememberEnabled =
                    await SecurityService.isRememberPasswordEnabled();
                if (!rememberEnabled) {
                  await SecurityService.clearSavedCredentials();
                }

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
              color: Colors.black.withValues(alpha: 0.08),
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
