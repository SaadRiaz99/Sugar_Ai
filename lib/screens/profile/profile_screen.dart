import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../themes/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _medicationsController;
  String _gender = 'Male';
  String _smokingStatus = 'Never';
  String _exerciseFrequency = 'Sedentary';
  bool _familyHistory = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _ageController =
        TextEditingController(text: user?.age.toString() ?? '');
    _heightController =
        TextEditingController(text: user?.height.toString() ?? '');
    _weightController =
        TextEditingController(text: user?.weight.toString() ?? '');
    _medicationsController =
        TextEditingController(text: user?.currentMedications ?? '');
    _gender = user?.gender ?? 'Male';
    _smokingStatus = user?.smokingStatus ?? 'Never';
    _exerciseFrequency = user?.exerciseFrequency ?? 'Sedentary';
    _familyHistory = user?.familyHistory ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  double _calculateBMI(double weight, double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return double.parse((weight / (heightM * heightM)).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final profileState = ref.watch(profileProvider);

    ref.listen(profileProvider, (_, state) {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: AppTheme.errorColor),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outlined),
                validator: Validators.validateName,
                fontSize: 16,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _ageController,
                      label: 'Age',
                      hint: 'Years',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.cake_outlined),
                      validator: Validators.validateAge,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: AppConstants.genderOptions
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g, style: const TextStyle(fontSize: 16)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      hint: 'e.g. 170',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.height),
                      validator: Validators.validateHeight,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      hint: 'e.g. 70',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.monitor_weight),
                      validator: Validators.validateWeight,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (_heightController.text.isNotEmpty &&
                  _weightController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'BMI: ${_calculateBMI(
                      double.tryParse(_weightController.text) ?? 0,
                      double.tryParse(_heightController.text) ?? 0,
                    )}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Health Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _smokingStatus,
                decoration: const InputDecoration(
                  labelText: 'Smoking Status',
                  prefixIcon: Icon(Icons.smoking_rooms),
                ),
                items: AppConstants.smokingOptions
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 16)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _smokingStatus = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _exerciseFrequency,
                decoration: const InputDecoration(
                  labelText: 'Exercise Frequency',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                items: AppConstants.exerciseOptions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, style: const TextStyle(fontSize: 16)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _exerciseFrequency = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  'Family History of Diabetes',
                  style: TextStyle(fontSize: 16),
                ),
                subtitle: const Text(
                  'Immediate family member diagnosed',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                value: _familyHistory,
                onChanged: (v) => setState(() => _familyHistory = v),
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _medicationsController,
                label: 'Current Medications',
                hint: 'List any medications you take',
                prefixIcon: const Icon(Icons.medication_outlined),
                maxLines: 2,
                fontSize: 16,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Save Profile',
                isLoading: profileState.isLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final weight =
                        double.tryParse(_weightController.text) ?? 0;
                    final height =
                        double.tryParse(_heightController.text) ?? 0;
                    final bmi = _calculateBMI(weight, height);

                    final updatedUser = user!.copyWith(
                      name: _nameController.text.trim(),
                      age: int.tryParse(_ageController.text) ?? 0,
                      gender: _gender,
                      height: height,
                      weight: weight,
                      bmi: bmi,
                      familyHistory: _familyHistory,
                      smokingStatus: _smokingStatus,
                      exerciseFrequency: _exerciseFrequency,
                      currentMedications: _medicationsController.text.trim(),
                    );

                    ref.read(profileProvider.notifier).updateProfile(updatedUser);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile saved successfully'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
