import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../widgets/loading_state.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
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
        return _PostLoginGate(uid: user.uid);
      },
    );
  }
}

/// Giriş yapılmış kullanıcı için: ilk kez giriyorsa kısa tanıtımı gösterir,
/// aksi halde doğrudan uygulamanın kök ekranına geçer.
class _PostLoginGate extends StatefulWidget {
  const _PostLoginGate({required this.uid});

  final String uid;

  @override
  State<_PostLoginGate> createState() => _PostLoginGateState();
}

class _PostLoginGateState extends State<_PostLoginGate> {
  final _onboardingService = OnboardingService();
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = !_onboardingService.hasSeen(widget.uid);
  }

  void _finishOnboarding() {
    _onboardingService.markSeen(widget.uid);
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(onDone: _finishOnboarding);
    }
    return const RootScreen();
  }
}
