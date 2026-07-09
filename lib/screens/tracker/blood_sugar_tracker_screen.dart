import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/blood_sugar_record.dart';
import '../../providers/blood_sugar_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/blood_sugar_chart.dart';
import '../../widgets/common/disclaimer_banner.dart';
import 'add_blood_sugar_screen.dart';

class BloodSugarTrackerScreen extends ConsumerStatefulWidget {
  const BloodSugarTrackerScreen({super.key});

  @override
  ConsumerState<BloodSugarTrackerScreen> createState() =>
      _BloodSugarTrackerScreenState();
}

class _BloodSugarTrackerScreenState
    extends ConsumerState<BloodSugarTrackerScreen> {
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(bloodSugarProvider.notifier).loadRecords());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bloodSugarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Sugar Tracker'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.bar_chart),
            onPressed: () =>
                setState(() => _showChart = !_showChart),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddBloodSugarScreen()),
              );
              if (result == true) {
                ref.read(bloodSugarProvider.notifier).loadRecords();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const DisclaimerBanner(),
          if (_showChart && state.records.isNotEmpty)
            SizedBox(
              height: 320,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BloodSugarChart(
                  records: state.records,
                  period: ChartPeriod.weekly,
                ),
              ),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.records.isEmpty
                    ? _buildEmptyState()
                    : _buildRecordsList(state.records),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bloodtype,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No blood sugar records yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first reading',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<BloodSugarRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(record.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTypeIcon(record.type),
                color: _getTypeColor(record.type),
              ),
            ),
            title: Text(
              record.type.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${_formatDate(record.dateTime)}${record.notes.isNotEmpty ? ' - ${record.notes}' : ''}',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.value.toStringAsFixed(1)} ${record.type.unit}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  record.value > record.type.normalRangeHigh
                      ? 'High'
                      : record.value < record.type.normalRangeLow
                          ? 'Low'
                          : 'Normal',
                  style: TextStyle(
                    fontSize: 12,
                    color: record.value > record.type.normalRangeHigh
                        ? AppTheme.errorColor
                        : record.value < record.type.normalRangeLow
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                  ),
                ),
              ],
            ),
            onLongPress: () => _deleteRecord(record),
          ),
        );
      },
    );
  }

  void _deleteRecord(BloodSugarRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(bloodSugarProvider.notifier)
                  .deleteRecord(record.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(BloodSugarType type) {
    switch (type) {
      case BloodSugarType.fasting:
        return AppTheme.accentColor;
      case BloodSugarType.random:
        return AppTheme.primaryColor;
      case BloodSugarType.beforeMeal:
        return AppTheme.warningColor;
      case BloodSugarType.afterMeal:
        return AppTheme.successColor;
      case BloodSugarType.hba1c:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(BloodSugarType type) {
    switch (type) {
      case BloodSugarType.fasting:
        return Icons.nightlight_round;
      case BloodSugarType.random:
        return Icons.schedule;
      case BloodSugarType.beforeMeal:
        return Icons.restaurant;
      case BloodSugarType.afterMeal:
        return Icons.restaurant_menu;
      case BloodSugarType.hba1c:
        return Icons.science;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
