import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/security_service.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

/// Stateful on purpose: controllers created in `build()` leak (never disposed)
/// and every rebuild silently wipes whatever the user had typed.
class ChangePasswordPage extends StatefulWidget {
  static const route = '/change-password';
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const int _minPasswordLength = 8;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validate() {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      return 'Please fill all fields.';
    }
    if (newPassword.length < _minPasswordLength) {
      return 'New password must be at least $_minPasswordLength characters.';
    }
    if (newPassword == oldPassword) {
      return 'New password must be different from the current one.';
    }
    if (newPassword != _confirmPasswordController.text) {
      return 'New passwords do not match.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await AuthService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      // The stored credential is now stale. Left alone, the login screen
      // prefills the old password and biometric login replays it forever.
      await SecurityService.updateSavedPassword(_newPasswordController.text);

      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('Change Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text('Current Password',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Enter Your Password',
              obscure: !_isOldPasswordVisible,
              controller: _oldPasswordController,
              suffix: IconButton(
                icon: Icon(
                  _isOldPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () => setState(
                    () => _isOldPasswordVisible = !_isOldPasswordVisible),
              ),
            ),
            const SizedBox(height: 16),
            const Text('New Password',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Enter Your new Password',
              obscure: !_isNewPasswordVisible,
              controller: _newPasswordController,
              suffix: IconButton(
                icon: Icon(
                  _isNewPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () => setState(
                    () => _isNewPasswordVisible = !_isNewPasswordVisible),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Confirm New Password',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppTextField(
              hint: 'Re-enter Your new Password',
              obscure: !_isConfirmPasswordVisible,
              controller: _confirmPasswordController,
              suffix: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() =>
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isLoading ? 'Saving...' : 'Save Changes',
              onPressed: _isLoading ? null : _submit,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
