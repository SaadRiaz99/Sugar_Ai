import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../utils/encryption_helper.dart';

class AuthService {
  final DatabaseHelper _db = DatabaseHelper();
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('currentUserId');
    if (userId != null) {
      final userData = await _db.queryById('users', userId);
      if (userData != null) {
        _currentUser = User.fromMap(userData);
        return true;
      }
    }
    return false;
  }

  Future<String?> register(
      String name, String email, String password) async {
    try {
      final existingUsers = await _db.queryAll('users',
          where: 'email = ?', whereArgs: [email]);
      if (existingUsers.isNotEmpty) {
        return 'Email already registered';
      }

      final enc = EncryptionHelper();
      final passwordHash = enc.hashPassword(password);

      final user = User(
        name: name,
        age: 0,
        gender: 'Male',
        height: 170,
        weight: 70,
        bmi: 24.2,
        familyHistory: false,
        smokingStatus: 'Never',
        exerciseFrequency: 'Sedentary',
        currentMedications: '',
        email: email,
        passwordHash: passwordHash,
      );

      final id = await _db.insert('users', user.toMap());
      _currentUser = user.copyWith(id: id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentUserId', id!);

      return null;
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final users = await _db.queryAll('users',
          where: 'email = ?', whereArgs: [email]);
      if (users.isEmpty) {
        return 'User not found';
      }

      final user = User.fromMap(users.first);
      final enc = EncryptionHelper();
      final passwordHash = enc.hashPassword(password);

      if (user.passwordHash != passwordHash) {
        return 'Invalid password';
      }

      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentUserId', user.id!);

      return null;
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
  }

  Future<String?> updateProfile(User user) async {
    try {
      await _db.update('users', user.toMap(), user.id!);
      _currentUser = user;
      return null;
    } catch (e) {
      return 'Profile update failed: $e';
    }
  }

  void setCurrentUser(User user) {
    _currentUser = user;
  }
}
