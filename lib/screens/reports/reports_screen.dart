import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/blood_sugar_record.dart';
import '../../models/risk_prediction.dart';
import '../../providers/blood_sugar_provider.dart';
import '../../providers/risk_prediction_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bloodSugarProvider.notifier).loadRecords();
      ref.read(riskPredictionProvider.notifier).loadPredictions();
      ref.read(medicationProvider.notifier).loadReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBloodSugarSection(),
            const SizedBox(height: 16),
            _buildRiskSection(),
            const SizedBox(height: 16),
            _buildMedicationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSugarSection() {
    final records = ref.watch(bloodSugarProvider).records;
    final weeklyRecords = records
        .where((r) =>
            r.dateTime.isAfter(
                DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bloodtype, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Blood Sugar Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Records: ${records.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Records (7 days): ${weeklyRecords.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Average (7 days): ${_calculateAverage(weeklyRecords)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'By Type:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            ...BloodSugarType.values.map((type) {
              final typeRecords =
                  records.where((r) => r.type == type).toList();
              final avg = typeRecords.isNotEmpty
                  ? typeRecords.fold(0.0, (s, r) => s + r.value) /
                      typeRecords.length
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${type.displayName}: ${typeRecords.length} records, Avg: ${avg.toStringAsFixed(1)} ${type.unit}',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSection() {
    final predictions = ref.watch(riskPredictionProvider).predictions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: AppTheme.accentColor),
                SizedBox(width: 8),
                Text(
                  'Risk Prediction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Assessments: ${predictions.length}',
              style: const TextStyle(fontSize: 16),
            ),
            if (predictions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Latest: ${predictions.first.riskLevel.displayName} (${(predictions.first.confidenceScore * 100).toStringAsFixed(0)}% confidence)',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(predictions.first.createdAt)}',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationSection() {
    final reminders = ref.watch(medicationProvider).reminders;
    final activeReminders = reminders.where((r) => r.isActive).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medication, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Text(
                  'Medication Adherence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Reminders: ${reminders.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Active Reminders: ${activeReminders.length}',
              style: const TextStyle(fontSize: 16),
            ),
            if (activeReminders.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Active Medications:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              ...activeReminders.map((r) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${r.medicineName} - ${r.dosage} at ${r.time}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  String _calculateAverage(List<BloodSugarRecord> records) {
    if (records.isEmpty) return '--';
    final avg =
        records.fold(0.0, (s, r) => s + r.value) / records.length;
    return '${avg.toStringAsFixed(1)} mg/dL';
  }

  Future<void> _generatePdf() async {
    try {
      final user = ref.read(authProvider).user;
      final bloodSugarRecords = ref.read(bloodSugarProvider).records;
      final predictions = ref.read(riskPredictionProvider).predictions;
      final medications = ref.read(medicationProvider).reminders;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('SugarAI - Health Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Paragraph(
                text: 'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'User Information'),
            pw.Paragraph(text: 'Name: ${user?.name ?? 'N/A'}'),
            pw.Paragraph(text: 'Age: ${user?.age.toString() ?? 'N/A'}'),
            pw.Paragraph(text: 'BMI: ${user?.bmi.toStringAsFixed(1) ?? 'N/A'}'),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Blood Sugar Records'),
            pw.Paragraph(
                text: 'Total Records: ${bloodSugarRecords.length}'),
            if (bloodSugarRecords.isNotEmpty) ...[
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Date', 'Type', 'Value', 'Status'],
                data: bloodSugarRecords.take(20).map((r) {
                  final status = r.value > r.type.normalRangeHigh
                      ? 'High'
                      : r.value < r.type.normalRangeLow
                          ? 'Low'
                          : 'Normal';
                  return [
                    DateFormat('MMM dd').format(r.dateTime),
                    r.type.displayName,
                    '${r.value.toStringAsFixed(1)} ${r.type.unit}',
                    status,
                  ];
                }).toList(),
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Risk Predictions'),
            pw.Paragraph(
                text: 'Total Assessments: ${predictions.length}'),
            if (predictions.isNotEmpty) ...[
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Date', 'Risk Level', 'Confidence'],
                data: predictions.take(10).map((p) {
                  return [
                    DateFormat('MMM dd, yyyy').format(p.createdAt),
                    p.riskLevel.displayName,
                    '${(p.confidenceScore * 100).toStringAsFixed(0)}%',
                  ];
                }).toList(),
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: 'Medication Adherence'),
            pw.Paragraph(
                text: 'Active Reminders: ${medications.where((m) => m.isActive).length}'),
            if (medications.isNotEmpty) ...[
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Medicine', 'Dosage', 'Time', 'Status'],
                data: medications.map((m) {
                  return [
                    m.medicineName,
                    m.dosage,
                    m.time,
                    m.isActive ? 'Active' : 'Inactive',
                  ];
                }).toList(),
              ),
            ],
            pw.SizedBox(height: 40),
            pw.Paragraph(
              text:
                  'Disclaimer: This report is for informational purposes only. '
                  'It does not constitute medical advice. Please consult a '
                  'healthcare professional for diagnosis and treatment.',
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey,
              ),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/sugar_ai_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: file.path.split('\\').last,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
