import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final bool isComplete;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.isComplete = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    bool? isComplete,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const ProfileState());

  AuthService get _authService => _ref.read(authServiceProvider);

  Future<void> updateProfile(User user) async {
    state = state.copyWith(isLoading: true, error: null);
    final error = await _authService.updateProfile(user);
    if (error != null) {
      state = state.copyWith(isLoading: false, error: error);
    } else {
      _ref.read(authProvider.notifier).updateUser(user);
      state = state.copyWith(
        isLoading: false,
        isComplete: _isProfileComplete(user),
      );
    }
  }

  bool _isProfileComplete(User user) {
    return user.name.isNotEmpty &&
        user.age > 0 &&
        user.height > 0 &&
        user.weight > 0;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});
