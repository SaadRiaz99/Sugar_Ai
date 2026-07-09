import 'dart:math';
import '../models/risk_prediction.dart';

class PredictionResult {
  final RiskLevel riskLevel;
  final double confidenceScore;
  final String lifestyleSuggestions;

  PredictionResult({
    required this.riskLevel,
    required this.confidenceScore,
    required this.lifestyleSuggestions,
  });
}

class RiskPredictor {
  bool _modelLoaded = false;

  Future<void> loadModel() async {
    _modelLoaded = true;
  }

  bool get isModelLoaded => _modelLoaded;

  Future<PredictionResult> predict({
    required double age,
    required double bmi,
    required double bloodSugar,
    required double hba1c,
    required int exerciseFrequency,
    required bool familyHistory,
  }) async {
    if (!_modelLoaded) {
      await loadModel();
    }

    final result = _ruleBasedPrediction(
      age: age,
      bmi: bmi,
      bloodSugar: bloodSugar,
      hba1c: hba1c,
      exerciseFrequency: exerciseFrequency,
      familyHistory: familyHistory,
    );

    String suggestions = _generateSuggestions(
      riskLevel: result.riskLevel,
      bmi: bmi,
      exerciseFrequency: exerciseFrequency,
      bloodSugar: bloodSugar,
    );

    return PredictionResult(
      riskLevel: result.riskLevel,
      confidenceScore: result.confidenceScore,
      lifestyleSuggestions: suggestions,
    );
  }

  PredictionResult _ruleBasedPrediction({
    required double age,
    required double bmi,
    required double bloodSugar,
    required double hba1c,
    required int exerciseFrequency,
    required bool familyHistory,
  }) {
    double riskScore = 0.0;
    int factors = 0;

    if (age > 45) {
      riskScore += 0.2;
      factors++;
    }
    if (age > 60) {
      riskScore += 0.1;
    }

    if (bmi > 25) {
      riskScore += 0.15;
      factors++;
    }
    if (bmi > 30) {
      riskScore += 0.15;
    }

    if (bloodSugar > 100) {
      riskScore += 0.15;
      factors++;
    }
    if (bloodSugar > 126) {
      riskScore += 0.2;
    }

    if (hba1c > 5.7) {
      riskScore += 0.2;
      factors++;
    }
    if (hba1c > 6.5) {
      riskScore += 0.2;
    }

    if (exerciseFrequency < 2) {
      riskScore += 0.1;
      factors++;
    }

    if (familyHistory) {
      riskScore += 0.15;
      factors++;
    }

    riskScore = riskScore.clamp(0.0, 1.0);

    RiskLevel riskLevel;
    if (riskScore < 0.3) {
      riskLevel = RiskLevel.low;
    } else if (riskScore < 0.6) {
      riskLevel = RiskLevel.moderate;
    } else {
      riskLevel = RiskLevel.high;
    }

    final confidenceScore = min(0.95, 0.5 + (factors * 0.08));

    return PredictionResult(
      riskLevel: riskLevel,
      confidenceScore: confidenceScore,
      lifestyleSuggestions: '',
    );
  }

  String _generateSuggestions({
    required RiskLevel riskLevel,
    required double bmi,
    required int exerciseFrequency,
    required double bloodSugar,
  }) {
    final suggestions = <String>[];

    suggestions.add(
      'Maintain a balanced diet rich in fiber, vegetables, and whole grains.');

    if (bmi > 25) {
      suggestions.add(
        'Consider a weight management plan. A 5-7% reduction in body weight can significantly improve insulin sensitivity.');
    }

    if (exerciseFrequency < 3) {
      suggestions.add(
        'Aim for at least 150 minutes of moderate exercise per week, such as brisk walking, swimming, or cycling.');
    }

    if (bloodSugar > 100) {
      suggestions.add(
        'Monitor your carbohydrate intake. Choose complex carbohydrates over simple sugars.');
    }

    if (riskLevel == RiskLevel.high) {
      suggestions.add(
        'Please consult a healthcare professional for a comprehensive diabetes screening.');
      suggestions.add(
        'Consider regular blood sugar monitoring and maintain a food diary.');
    }

    if (riskLevel == RiskLevel.moderate) {
      suggestions.add(
        'Regular check-ups every 6-12 months are recommended to monitor your blood sugar levels.');
    }

    suggestions.add(
      'Stay hydrated by drinking at least 8 glasses of water daily.');

    return suggestions.join('\n\n');
  }

  String getAnswer(String question) {
    final q = question.toLowerCase();

    if (q.contains('what is diabetes') || q.contains('define diabetes')) {
      return 'Diabetes is a chronic condition that affects how your body turns food into energy. '
          'There are two main types: Type 1, where the body produces little to no insulin, and Type 2, '
          'where the body becomes resistant to insulin. It is characterized by high blood sugar levels. '
          'This information is for educational purposes only. Please consult a healthcare professional '
          'for medical advice.';
    }

    if (q.contains('food') && (q.contains('recommend') || q.contains('eat') || q.contains('diet'))) {
      return 'Recommended foods for maintaining healthy blood sugar include: leafy green vegetables, '
          'whole grains like oats and quinoa, lean proteins like fish and chicken, nuts and seeds, '
          'berries, and legumes. Foods rich in fiber help slow down sugar absorption. '
          'This is general dietary guidance, not medical advice. Please consult a dietitian or doctor '
          'for personalized recommendations.';
    }

    if ((q.contains('food') && (q.contains('avoid') || q.contains('limit') || q.contains('not'))) ||
        q.contains('restrict')) {
      return 'Foods to limit for healthy blood sugar management include: sugary beverages, refined white bread '
          'and pasta, sweetened cereals, high-sugar desserts, fried foods, and processed snacks high in '
          'trans fats. Moderation is key - you do not need to eliminate these entirely, but reduce intake. '
          'This is general guidance, not medical advice.';
    }

    if (q.contains('exercise') || q.contains('physical activity')) {
      return 'Exercise helps lower blood sugar by increasing insulin sensitivity. When you exercise, your muscles '
          'use glucose for energy, which helps reduce blood sugar levels. Both aerobic exercise (walking, swimming, '
          'cycling) and resistance training (weight lifting) are beneficial. Aim for 150 minutes of moderate '
          'activity weekly. Always consult your doctor before starting a new exercise routine.';
    }

    if (q.contains('hba1c') || q.contains('a1c') || q.contains('hemoglobin')) {
      return 'HbA1c (Hemoglobin A1c) is a blood test that measures your average blood sugar levels over the past '
          '2-3 months. It shows the percentage of hemoglobin proteins in your red blood cells that are coated with '
          'sugar. A normal HbA1c level is below 5.7%, while 5.7-6.4% indicates prediabetes, and 6.5% or higher '
          'may indicate diabetes. This is educational information only.';
    }

    if (q.contains('symptom')) {
      return 'Common symptoms of high blood sugar include: increased thirst, frequent urination, fatigue, '
          'blurred vision, slow-healing wounds, and unexplained weight loss. However, many people with '
          'prediabetes or early Type 2 diabetes have no symptoms. Regular check-ups are important. '
          'If you have concerns about your symptoms, please consult a healthcare professional.';
    }

    if (q.contains('prevent') || q.contains('prevention')) {
      return 'While not all types of diabetes are preventable, you can reduce your risk of Type 2 diabetes through: '
          'maintaining a healthy weight, being physically active, eating a balanced diet, avoiding smoking, '
          'limiting alcohol consumption, and managing stress. Regular screening is especially important if you '
          'have risk factors like family history or being overweight.';
    }

    return 'I am an educational AI assistant for diabetes awareness. I can answer questions about diabetes, '
        'diet, exercise, blood sugar monitoring, and healthy lifestyle habits. '
        'Please note that I cannot provide medical diagnoses or treatment recommendations. '
        'For personalized medical advice, please consult a qualified healthcare professional. '
        'You can ask me about: What is diabetes? recommended foods, foods to limit, exercise, HbA1c, '
        'symptoms, or prevention tips.';
  }
}
