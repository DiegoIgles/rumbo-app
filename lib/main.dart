import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_controller.dart';
import 'theme.dart';

void main() {
  runApp(const RumboApp());
}

class RumboApp extends StatelessWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController()..bootstrap(),
      child: MaterialApp(
        title: 'Rumbo',
        debugShowCheckedModeBanner: false,
        theme: buildRumboTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    switch (auth.status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedIn:
        return const HomeShell();
      case AuthStatus.signedOut:
        return const LoginScreen();
    }
  }
}
