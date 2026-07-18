import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final User? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final loggedIn = await _authService.isLoggedIn();
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: loggedIn,
      user: _authService.currentUser,
    );
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final error = await _authService.register(name, email, password);
    if (error != null) {
      state = state.copyWith(isLoading: false, error: error);
    } else {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: _authService.currentUser,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final error = await _authService.login(email, password);
    if (error != null) {
      state = state.copyWith(isLoading: false, error: error);
    } else {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: _authService.currentUser,
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
