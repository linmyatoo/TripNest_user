import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class ChangePasswordPage extends StatelessWidget {
  static const route = '/change-password';
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    ValueNotifier<bool> isLoading = ValueNotifier(false);
    ValueNotifier<String?> errorMessage = ValueNotifier(null);
    ValueNotifier<bool> isOldPasswordVisible = ValueNotifier(false);
    ValueNotifier<bool> isNewPasswordVisible = ValueNotifier(false);
    ValueNotifier<bool> isConfirmPasswordVisible = ValueNotifier(false);

    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('Change Password')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text('Current Password',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: isOldPasswordVisible,
              builder: (context, isVisible, _) {
                return AppTextField(
                  hint: 'Enter Your Password',
                  obscure: !isVisible,
                  controller: oldPasswordController,
                  suffix: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      isOldPasswordVisible.value = !isOldPasswordVisible.value;
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('New Password',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: isNewPasswordVisible,
              builder: (context, isVisible, _) {
                return AppTextField(
                  hint: 'Enter Your new Password',
                  obscure: !isVisible,
                  controller: newPasswordController,
                  suffix: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      isNewPasswordVisible.value = !isNewPasswordVisible.value;
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Confirm New Password',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: isConfirmPasswordVisible,
              builder: (context, isVisible, _) {
                return AppTextField(
                  hint: 'Re-enter Your new Password',
                  obscure: !isVisible,
                  controller: confirmPasswordController,
                  suffix: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, child) {
                return PrimaryButton(
                  label: loading ? 'Saving...' : 'Save Changes',
                  onPressed: loading
                      ? null
                      : () async {
                          errorMessage.value = null;
                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            errorMessage.value = 'New passwords do not match.';
                            return;
                          }
                          if (oldPasswordController.text.isEmpty ||
                              newPasswordController.text.isEmpty) {
                            errorMessage.value = 'Please fill all fields.';
                            return;
                          }
                          isLoading.value = true;
                          try {
                            await AuthService.changePassword(
                              oldPassword: oldPasswordController.text,
                              newPassword: newPasswordController.text,
                            );
                            await AuthService.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login', (route) => false);
                            }
                          } catch (e) {
                            errorMessage.value =
                                e.toString().replaceFirst('Exception: ', '');
                          } finally {
                            isLoading.value = false;
                          }
                        },
                );
              },
            ),
            ValueListenableBuilder<String?>(
              valueListenable: errorMessage,
              builder: (context, error, child) {
                if (error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
