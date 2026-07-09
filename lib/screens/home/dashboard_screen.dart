import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_sugar_provider.dart';
import '../../providers/risk_prediction_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/disclaimer_banner.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/quick_action_card.dart';
import '../tracker/blood_sugar_tracker_screen.dart';
import '../prediction/risk_prediction_screen.dart';
import '../assistant/health_assistant_screen.dart';
import '../reminders/medication_reminder_screen.dart';
import '../reminders/water_reminder_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bloodSugarProvider.notifier).loadRecords();
      ref.read(riskPredictionProvider.notifier).loadPredictions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final bloodSugarState = ref.watch(bloodSugarProvider);
    final predictionState = ref.watch(riskPredictionProvider);

    final todayRecords = bloodSugarState.records
        .where((r) =>
            r.dateTime.day == DateTime.now().day &&
            r.dateTime.month == DateTime.now().month &&
            r.dateTime.year == DateTime.now().year)
        .toList();

    final todayValue = todayRecords.isNotEmpty
        ? todayRecords.first.value.toStringAsFixed(1)
        : '--';

    final weeklyRecords = bloodSugarState.records
        .where((r) =>
            r.dateTime
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    final weeklyAvg = weeklyRecords.isNotEmpty
        ? (weeklyRecords.fold(0.0, (s, r) => s + r.value) /
                weeklyRecords.length)
            .toStringAsFixed(1)
        : '--';

    final lastRisk = predictionState.lastPrediction;
    final lastPredictionText = lastRisk != null
        ? lastRisk.riskLevel.displayName
        : 'No prediction';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('$greeting, ${user?.name.split(' ').first ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DisclaimerBanner(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Today\'s Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            StatCard(
              title: 'Today\'s Blood Sugar',
              value: todayValue,
              icon: Icons.bloodtype,
              iconColor: AppTheme.primaryColor,
              subtitle: 'Latest reading',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BloodSugarTrackerScreen()),
                );
              },
            ),
            StatCard(
              title: 'Weekly Average',
              value: '$weeklyAvg mg/dL',
              icon: Icons.trending_up,
              iconColor: AppTheme.accentColor,
              subtitle: 'Last 7 days',
            ),
            StatCard(
              title: 'Last Risk Prediction',
              value: lastPredictionText,
              icon: Icons.assessment,
              iconColor: lastRisk?.riskLevel == RiskLevel.high
                  ? AppTheme.errorColor
                  : lastRisk?.riskLevel == RiskLevel.moderate
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
              subtitle: lastRisk != null
                  ? DateFormat('MMM dd, yyyy').format(lastRisk.createdAt)
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RiskPredictionScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      title: 'Log Blood\nSugar',
                      icon: Icons.bloodtype,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const BloodSugarTrackerScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      title: 'Risk\nPrediction',
                      icon: Icons.assessment,
                      color: AppTheme.accentColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RiskPredictionScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      title: 'AI\nAssistant',
                      icon: Icons.smart_toy,
                      color: AppTheme.warningColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HealthAssistantScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      title: 'Medications',
                      icon: Icons.medication,
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const MedicationReminderScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      title: 'Water\nReminder',
                      icon: Icons.water_drop,
                      color: AppTheme.accentColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WaterReminderScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      title: 'Health\nReports',
                      icon: Icons.description,
                      color: AppTheme.successColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
