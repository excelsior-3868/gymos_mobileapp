import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/gym_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui_components.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _healthController = TextEditingController();
  final _goalsController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final gym = Provider.of<GymProvider>(context, listen: false);
    final m = gym.me?.member;
    if (m != null) {
      _emailController.text = m.email ?? '';
      _addressController.text = m.address ?? '';
      _emergencyController.text = m.emergencyContact ?? '';
      _healthController.text = m.healthConditions ?? '';
      _goalsController.text = m.fitnessGoals ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    _healthController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    if (email.isEmpty) return true;
    return RegExp(r'^\S+@\S+\.\S+$').hasMatch(email);
  }

  Future<void> _handleSave() async {
    if (!_isEmailValid) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final gym = Provider.of<GymProvider>(context, listen: false);
      await gym.updateProfile({
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'emergencyContact': _emergencyController.text.trim().isEmpty ? null : _emergencyController.text.trim(),
        'healthConditions': _healthController.text.trim().isEmpty ? null : _healthController.text.trim(),
        'fitnessGoals': _goalsController.text.trim().isEmpty ? null : _goalsController.text.trim(),
      });

      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = Provider.of<GymProvider>(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final member = gym.me?.member;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, bottomPadding + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              title: 'Personal details',
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),

            // Gym Managed Section
            if (member != null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MANAGED BY THE GYM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildReadOnlyRow('Full name', member.fullName),
                    const Divider(height: 16, color: AppColors.border),
                    _buildReadOnlyRow('Mobile', member.phone),
                    const Divider(height: 16, color: AppColors.border),
                    _buildReadOnlyRow('Date of birth', AppFormat.formatDate(member.dob)),
                    const Divider(height: 16, color: AppColors.border),
                    _buildReadOnlyRow('Blood group', member.bloodGroup ?? '—'),
                    const SizedBox(height: 10),
                    const Text(
                      'To change these, please ask the front desk.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // User Editable Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'YOU CAN EDIT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'name@example.com',
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Address',
                    controller: _addressController,
                    hint: 'Your home address',
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Emergency contact',
                    controller: _emergencyController,
                    hint: 'Name and phone number',
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Health conditions',
                    controller: _healthController,
                    hint: 'Injuries, allergies, medication…',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Fitness goals',
                    controller: _goalsController,
                    hint: 'e.g. Lose 5 kg, build strength',
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.danger),
                ),
              ),
            ],

            const SizedBox(height: 24),
            AppButton(
              title: 'Save changes',
              loading: _isSaving,
              onPress: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 15, color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 10 : 8),
            ),
          ),
        ),
      ],
    );
  }
}
