import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

/// Shows a password reset dialog prefilled with [initialEmail] if provided.
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  String? initialEmail,
}) async {
  final controller = TextEditingController(text: initialEmail ?? '');
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  await showDialog(
    context: context,
    barrierDismissible: !loading,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> send() async {
            if (!formKey.currentState!.validate()) return;

            setDialogState(() => loading = true);

            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(
                email: controller.text.trim(),
              );

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (!context.mounted) return;
              showAppSnackBar(
                context,
                'Reset link sent to ${controller.text.trim()}',
                kind: SnackKind.success,
              );
            } on FirebaseAuthException catch (e) {
              if (!dialogContext.mounted) return;
              setDialogState(() => loading = false);

              String message = 'Failed to send reset link.';
              if (e.code == 'user-not-found') {
                message = 'No account was found with this email.';
              } else if (e.code == 'invalid-email') {
                message = 'Please enter a valid email address.';
              } else if (e.code == 'too-many-requests') {
                message = 'Too many attempts. Try again later.';
              }

              showAppSnackBar(dialogContext, message, kind: SnackKind.error);
            } catch (_) {
              if (!dialogContext.mounted) return;
              setDialogState(() => loading = false);
              showAppSnackBar(
                dialogContext,
                'Something went wrong. Please try again.',
                kind: SnackKind.error,
              );
            }
          }

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon hero
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.heroGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Reset your password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Enter the email tied to your account and we\'ll send '
                      'a reset link.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your email.';
                        }
                        if (!v.contains('@')) {
                          return 'Please enter a valid email.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => send(),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: loading
                                ? null
                                : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: loading ? null : send,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Send Link'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  Future.delayed(const Duration(milliseconds: 250), controller.dispose);
}
