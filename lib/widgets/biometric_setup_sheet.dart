import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'ui_components.dart';

class BiometricSetupSheet extends StatefulWidget {
  final String? username;
  final bool isFirstTimePrompt;
  final bool requirePassword;

  const BiometricSetupSheet({
    super.key,
    this.username,
    this.isFirstTimePrompt = false,
    this.requirePassword = false,
  });

  /// Shows the biometric setup sheet. Returns true if biometrics were enabled.
  static Future<bool> show(
    BuildContext context, {
    String? username,
    bool isFirstTimePrompt = false,
    bool requirePassword = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => BiometricSetupSheet(
        username: username,
        isFirstTimePrompt: isFirstTimePrompt,
        requirePassword: requirePassword,
      ),
    );

    if (result != true && isFirstTimePrompt && context.mounted) {
      await Provider.of<AuthProvider>(context, listen: false).dismissBiometricSetup();
    }

    return result == true;
  }

  @override
  State<BiometricSetupSheet> createState() => _BiometricSetupSheetState();
}

class _BiometricSetupSheetState extends State<BiometricSetupSheet> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEnable() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final needsPassword = widget.requirePassword || !auth.hasSessionPassword;
    final typedPassword = _passwordController.text.trim();

    if (needsPassword && typedPassword.isEmpty) {
      setState(() => _error = 'Please enter your current password to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await auth.enableBiometric(
        username: widget.username,
        password: needsPassword ? typedPassword : null,
      );

      if (!mounted) return;

      if (res.success) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${auth.biometricLabel} login enabled!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (!res.cancelled) {
        setState(() => _error = res.error ?? 'Could not verify ${auth.biometricLabel}.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final label = auth.biometricLabel;
    final isFace = label.toLowerCase().contains('face');
    final needsPassword = widget.requirePassword || !auth.hasSessionPassword;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + bottomSafe + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: IconBubble(
              name: isFace ? Icons.face_rounded : Icons.fingerprint_rounded,
              size: 64,
              color: AppColors.primary,
              bg: AppColors.primarySoft,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enable $label login',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in faster and securely with $label instead of typing your password every time. You can change this anytime in Profile.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          if (needsPassword) ...[
            const SizedBox(height: 20),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 20, color: AppColors.textFaint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 15, color: AppColors.text),
                      decoration: const InputDecoration(
                        hintText: 'Confirm your password',
                        hintStyle: TextStyle(color: AppColors.textFaint),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _handleEnable(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          AppButton(
            title: 'Enable $label',
            icon: isFace ? Icons.face_rounded : Icons.fingerprint_rounded,
            loading: _isLoading,
            onPress: _handleEnable,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context, false),
            child: Text(
              widget.isFirstTimePrompt ? 'Not now' : 'Cancel',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
