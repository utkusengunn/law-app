import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/loading_state.dart';
import 'login_screen.dart';
import 'root_screen.dart';

/// Oturum durumuna göre giriş ekranı veya uygulamanın kök ekranı arasında
/// geçiş yapan kapı widget'ı. main.dart içinde `home` olarak kullanılır.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingState());
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        return const RootScreen();
      },
    );
  }
}
