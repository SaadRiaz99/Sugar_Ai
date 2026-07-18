import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/medication_reminder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../themes/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class MedicationReminderScreen extends ConsumerStatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  ConsumerState<MedicationReminderScreen> createState() =>
      _MedicationReminderScreenState();
}

class _MedicationReminderScreenState
    extends ConsumerState<MedicationReminderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(medicationProvider.notifier).loadReminders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.reminders.isEmpty
              ? _buildEmptyState()
              : _buildRemindersList(state.reminders),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No medication reminders',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text("Tap + to add a reminder",
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRemindersList(List<MedicationReminder> reminders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (reminder.isActive
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication,
                color: reminder.isActive
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
            title: Text(
              reminder.medicineName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${reminder.dosage} - ${reminder.time}'),
                if (reminder.notes.isNotEmpty)
                  Text(reminder.notes,
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Switch(
              value: reminder.isActive,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) {
                ref
                    .read(medicationProvider.notifier)
                    .toggleReminder(reminder.id!, v);
              },
            ),
            onLongPress: () => _deleteReminder(reminder),
            onTap: () => _showEditDialog(reminder),
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    _showReminderDialog();
  }

  void _showEditDialog(MedicationReminder reminder) {
    _showReminderDialog(reminder: reminder);
  }

  void _showReminderDialog({MedicationReminder? reminder}) {
    final nameController =
        TextEditingController(text: reminder?.medicineName ?? '');
    final dosageController =
        TextEditingController(text: reminder?.dosage ?? '');
    final timeController =
        TextEditingController(text: reminder?.time ?? '');
    final notesController =
        TextEditingController(text: reminder?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    TimeOfDay selectedTime = reminder != null
        ? TimeOfDay(
            hour: int.tryParse(reminder.time.split(':')[0]) ?? 8,
            minute: int.tryParse(reminder.time.split(':')[1]) ?? 0,
          )
        : const TimeOfDay(hour: 8, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reminder == null
                            ? 'Add Reminder'
                            : 'Edit Reminder',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: nameController,
                        label: 'Medicine Name',
                        hint: 'e.g. Metformin',
                        prefixIcon: const Icon(Icons.medication_outlined),
                        validator: Validators.validateMedicineName,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: dosageController,
                              label: 'Dosage',
                              hint: 'e.g. 500mg',
                              prefixIcon: const Icon(Icons.speed),
                              validator: Validators.validateDosage,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: timeController,
                              label: 'Time',
                              readOnly: true,
                              prefixIcon:
                                  const Icon(Icons.access_time),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedTime,
                                );
                                if (time != null) {
                                  selectedTime = time;
                                  timeController.text =
                                      time.format(context);
                                }
                              },
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: notesController,
                        label: 'Notes (optional)',
                        hint: 'e.g. Take with food',
                        prefixIcon: const Icon(Icons.notes),
                        maxLines: 2,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: reminder == null
                            ? 'Save Reminder'
                            : 'Update Reminder',
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final r = MedicationReminder(
                            id: reminder?.id,
                            userId:
                                ref.read(authProvider).user?.id ?? 0,
                            medicineName:
                                nameController.text.trim(),
                            dosage: dosageController.text.trim(),
                            time: timeController.text,
                            notes: notesController.text.trim(),
                            isActive: reminder?.isActive ?? true,
                          );
                          if (reminder == null) {
                            ref
                                .read(medicationProvider.notifier)
                                .addReminder(r);
                          } else {
                            ref
                                .read(medicationProvider.notifier)
                                .updateReminder(r);
                          }
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteReminder(MedicationReminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text(
            'Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(medicationProvider.notifier)
                  .deleteReminder(reminder.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
