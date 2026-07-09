import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/blood_sugar_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_sugar_provider.dart';
import '../../themes/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class AddBloodSugarScreen extends ConsumerStatefulWidget {
  const AddBloodSugarScreen({super.key});

  @override
  ConsumerState<AddBloodSugarScreen> createState() =>
      _AddBloodSugarScreenState();
}

class _AddBloodSugarScreenState extends ConsumerState<AddBloodSugarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  BloodSugarType _selectedType = BloodSugarType.fasting;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reading'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blood Sugar Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...BloodSugarType.values.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<BloodSugarType>(
                            value: type,
                            groupValue: _selectedType,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (v) =>
                                setState(() => _selectedType = v!),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Normal: ${type.normalRangeLow}-${type.normalRangeHigh} ${type.unit}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              AppTextField(
                controller: _valueController,
                label: 'Value (${_selectedType.unit})',
                hint: 'Enter your reading',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.edit),
                validator: _selectedType == BloodSugarType.hba1c
                    ? Validators.validateHba1c
                    : Validators.validateBloodSugar,
                fontSize: 16,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Date',
                      readOnly: true,
                      controller: TextEditingController(
                        text:
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                      onTap: () => _pickDate(),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Time',
                      readOnly: true,
                      controller: TextEditingController(
                        text: _selectedTime.format(context),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                      onTap: () => _pickTime(),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _notesController,
                label: 'Notes (optional)',
                hint: 'Add any notes...',
                prefixIcon: const Icon(Icons.notes),
                maxLines: 2,
                fontSize: 16,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Save Reading',
                onPressed: _saveRecord,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _saveRecord() {
    if (!_formKey.currentState!.validate()) return;

    final value = double.parse(_valueController.text);
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final userId = ref.read(authProvider).user?.id ?? 0;
    if (userId == 0) return;

    final record = BloodSugarRecord(
      userId: userId,
      type: _selectedType,
      value: value,
      dateTime: dateTime,
      notes: _notesController.text.trim(),
    );

    ref.read(bloodSugarProvider.notifier).addRecord(record).then((error) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    });
  }
}
