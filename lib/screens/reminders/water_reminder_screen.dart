import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/water_reminder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/water_reminder_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/app_button.dart';

class WaterReminderScreen extends ConsumerStatefulWidget {
  const WaterReminderScreen({super.key});

  @override
  ConsumerState<WaterReminderScreen> createState() =>
      _WaterReminderScreenState();
}

class _WaterReminderScreenState extends ConsumerState<WaterReminderScreen> {
  int _selectedInterval = 60;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(waterReminderProvider.notifier).loadReminders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waterReminderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Reminder'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      Icons.water_drop,
                      size: 80,
                      color: AppTheme.accentColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stay Hydrated',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Drinking enough water is essential for your health.\nSet a reminder interval below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Reminder Interval',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildIntervalOptions(),
                  const SizedBox(height: 24),
                  AppButton(
                    text: state.reminders.isEmpty
                        ? 'Start Reminder'
                        : 'Update Reminder',
                    onPressed: _saveReminder,
                  ),
                  if (state.reminders.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Active Reminders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...state.reminders.map((reminder) => Card(
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (reminder.isActive
                                        ? AppTheme.accentColor
                                        : AppTheme.textSecondary)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.water_drop,
                                color: reminder.isActive
                                    ? AppTheme.accentColor
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            title: Text(
                              'Every ${reminder.intervalMinutes} minutes',
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: Switch(
                              value: reminder.isActive,
                              activeColor: AppTheme.accentColor,
                              onChanged: (v) {
                                ref
                                    .read(waterReminderProvider.notifier)
                                    .toggleReminder(reminder.id!, v);
                              },
                            ),
                            onLongPress: () {
                              ref
                                  .read(waterReminderProvider.notifier)
                                  .deleteReminder(reminder.id!);
                            },
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  List<Widget> _buildIntervalOptions() {
    const intervals = [
      {'value': 30, 'label': 'Every 30 minutes'},
      {'value': 60, 'label': 'Every 1 hour'},
      {'value': 90, 'label': 'Every 1.5 hours'},
      {'value': 120, 'label': 'Every 2 hours'},
    ];

    return intervals.map((interval) {
      final value = interval['value'] as int;
      final label = interval['label'] as String;
      final isSelected = _selectedInterval == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => setState(() => _selectedInterval = value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentColor
                    : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<int>(
                  value: value,
                  groupValue: _selectedInterval,
                  activeColor: AppTheme.accentColor,
                  onChanged: (v) =>
                      setState(() => _selectedInterval = v!),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _saveReminder() {
    final userId = ref.read(authProvider).user?.id ?? 0;
    if (userId == 0) return;

    final state = ref.read(waterReminderProvider);

    if (state.reminders.isNotEmpty) {
      final existing = state.reminders.first;
      ref.read(waterReminderProvider.notifier).updateReminder(
            existing.copyWith(intervalMinutes: _selectedInterval),
          );
    } else {
      ref.read(waterReminderProvider.notifier).addReminder(
            WaterReminder(
              userId: userId,
              intervalMinutes: _selectedInterval,
            ),
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Water reminder saved'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
