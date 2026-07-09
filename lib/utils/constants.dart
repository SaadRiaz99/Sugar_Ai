class AppConstants {
  static const String appName = 'SugarAI';
  static const String appVersion = '1.0.0';

  static const String dbName = 'sugar_ai.db';
  static const int dbVersion = 1;

  static const String encryptionKey = 'sugar_ai_encrypt_key_32chr!!';
  static const String preferencesKey = 'sugar_ai_prefs';

  static const double minAge = 1;
  static const double maxAge = 120;
  static const double minHeight = 50;
  static const double maxHeight = 300;
  static const double minWeight = 10;
  static const double maxWeight = 500;
  static const double minBloodSugar = 20;
  static const double maxBloodSugar = 600;
  static const double minHba1c = 2.0;
  static const double maxHba1c = 20.0;

  static const List<String> genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> smokingOptions = [
    'Never',
    'Former',
    'Current',
  ];
  static const List<String> exerciseOptions = [
    'Sedentary',
    'Light (1-2 days/week)',
    'Moderate (3-4 days/week)',
    'Heavy (5+ days/week)',
  ];
}
