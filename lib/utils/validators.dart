class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      return 'Enter a valid age (1-120)';
    }
    return null;
  }

  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }
    final height = double.tryParse(value);
    if (height == null || height < 50 || height > 300) {
      return 'Enter height in cm (50-300)';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    final weight = double.tryParse(value);
    if (weight == null || weight < 10 || weight > 500) {
      return 'Enter weight in kg (10-500)';
    }
    return null;
  }

  static String? validateBloodSugar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Value is required';
    }
    final bs = double.tryParse(value);
    if (bs == null || bs < 20 || bs > 600) {
      return 'Enter a valid value (20-600 mg/dL)';
    }
    return null;
  }

  static String? validateHba1c(String? value) {
    if (value == null || value.isEmpty) {
      return 'Value is required';
    }
    final hba1c = double.tryParse(value);
    if (hba1c == null || hba1c < 2.0 || hba1c > 20.0) {
      return 'Enter a valid HbA1c (2.0-20.0%)';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMedicineName(String? value) {
    return validateRequired(value, 'Medicine name');
  }

  static String? validateDosage(String? value) {
    return validateRequired(value, 'Dosage');
  }

  static String? validateTime(String? value) {
    return validateRequired(value, 'Time');
  }
}
