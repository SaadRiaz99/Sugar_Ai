import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'widgets/common/loading_indicator.dart';

class SugarAIApp extends ConsumerStatefulWidget {
  const SugarAIApp({super.key});

  @override
  ConsumerState<SugarAIApp> createState() => _SugarAIAppState();
}

class _SugarAIAppState extends ConsumerState<SugarAIApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuthStatus();
      ref.read(themeProvider.notifier).loadTheme();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'SugarAI',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    if (authState.isLoading) {
      return Scaffold(
        body: LoadingIndicator(message: 'Loading...'),
      );
    }

    if (authState.isLoggedIn) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
