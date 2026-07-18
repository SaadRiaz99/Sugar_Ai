import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/risk_prediction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/risk_prediction_provider.dart';
import '../../themes/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/disclaimer_banner.dart';
import '../../widgets/common/app_text_field.dart';
import '../profile/profile_screen.dart';

class RiskPredictionScreen extends ConsumerStatefulWidget {
  const RiskPredictionScreen({super.key});

  @override
  ConsumerState<RiskPredictionScreen> createState() =>
      _RiskPredictionScreenState();
}

class _RiskPredictionScreenState extends ConsumerState<RiskPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bloodSugarController = TextEditingController();
  final _hba1cController = TextEditingController();
  bool _showForm = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(riskPredictionProvider.notifier).loadPredictions();
    });
  }

  @override
  void dispose() {
    _bloodSugarController.dispose();
    _hba1cController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riskPredictionProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessment'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DisclaimerBanner(),
            if (_showForm)
              _buildPredictionForm(state, user!)
            else
              _buildResults(state),
            if (state.predictions.isNotEmpty && !_showForm)
              _buildHistory(state.predictions),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionForm(RiskPredictionState state, dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current readings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your profile data (age, BMI, etc.) will be used automatically.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _bloodSugarController,
              label: 'Latest Blood Sugar (mg/dL)',
              hint: 'Enter your blood sugar reading',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.bloodtype),
              fontSize: 16,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _hba1cController,
              label: 'Latest HbA1c (%)',
              hint: 'Enter your HbA1c value',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.science),
              fontSize: 16,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Assess My Risk',
              isLoading: state.isLoading,
              onPressed: _predictRisk,
            ),
            if (user != null && (user.age == 0 || user.bmi == 0))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.warning, color: AppTheme.warningColor),
                  label: const Text(
                    'Complete your profile for accurate prediction',
                    style: TextStyle(color: AppTheme.warningColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _predictRisk() {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final bloodSugar =
        double.tryParse(_bloodSugarController.text) ?? user.bmi;
    final hba1c =
        double.tryParse(_hba1cController.text) ?? 5.0;

    int exerciseVal = 0;
    if (user.exerciseFrequency.contains('Light')) exerciseVal = 1;
    if (user.exerciseFrequency.contains('Moderate')) exerciseVal = 2;
    if (user.exerciseFrequency.contains('Heavy')) exerciseVal = 3;

    ref
        .read(riskPredictionProvider.notifier)
        .predict(
          age: user.age.toDouble(),
          bmi: user.bmi,
          bloodSugar: bloodSugar,
          hba1c: hba1c,
          exerciseFrequency: exerciseVal,
          familyHistory: user.familyHistory,
        )
        .then((error) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error), backgroundColor: AppTheme.errorColor),
        );
      } else {
        setState(() => _showForm = false);
      }
    });
  }

  Widget _buildResults(RiskPredictionState state) {
    final prediction = state.lastPrediction;
    if (prediction == null) return const SizedBox.shrink();

    Color riskColor;
    IconData riskIcon;
    switch (prediction.riskLevel) {
      case RiskLevel.low:
        riskColor = AppTheme.successColor;
        riskIcon = Icons.check_circle;
      case RiskLevel.moderate:
        riskColor = AppTheme.warningColor;
        riskIcon = Icons.warning;
      case RiskLevel.high:
        riskColor = AppTheme.errorColor;
        riskIcon = Icons.error;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(riskIcon, size: 64, color: riskColor),
                  const SizedBox(height: 16),
                  Text(
                    prediction.riskLevel.displayName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Input Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Age', '${prediction.age.toStringAsFixed(0)} years'),
                  _buildSummaryRow('BMI', prediction.bmi.toStringAsFixed(1)),
                  _buildSummaryRow('Blood Sugar',
                      '${prediction.bloodSugar.toStringAsFixed(1)} mg/dL'),
                  _buildSummaryRow('HbA1c',
                      '${prediction.hba1c.toStringAsFixed(1)}%'),
                  _buildSummaryRow('Exercise', _getExerciseLabel(prediction.exerciseFrequency)),
                  _buildSummaryRow('Family History',
                      prediction.familyHistory ? 'Yes' : 'No'),
                ],
              ),
            ),
          ),
          if (prediction.lifestyleSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...prediction.lifestyleSuggestions
                        .split('\n\n')
                        .map((suggestion) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.primaryColor),
                                  ),
                                  Expanded(
                                    child: Text(
                                      suggestion,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            text: 'New Assessment',
            isOutlined: true,
            onPressed: () => setState(() => _showForm = true),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getExerciseLabel(int value) {
    const labels = ['Sedentary', 'Light', 'Moderate', 'Heavy'];
    return value < labels.length ? labels[value] : 'Unknown';
  }

  Widget _buildHistory(List<RiskPrediction> predictions) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prediction History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...predictions.take(5).map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    p.riskLevel == RiskLevel.low
                        ? Icons.check_circle
                        : p.riskLevel == RiskLevel.moderate
                            ? Icons.warning
                            : Icons.error,
                    color: p.riskLevel == RiskLevel.low
                        ? AppTheme.successColor
                        : p.riskLevel == RiskLevel.moderate
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                  ),
                  title: Text(p.riskLevel.displayName),
                  subtitle: Text(
                    '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}'),
                  trailing: Text(
                    '${(p.confidenceScore * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
