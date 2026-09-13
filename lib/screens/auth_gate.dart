import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
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

/// Giriş yapılmış kullanıcı için: önce Firestore'daki müvekkil/dosya
/// verisinin ilk yüklemesini bekler (D019, 2026-09-13 - Client/Case artık
/// cihazda değil bulutta), sonra ilk kez giriyorsa kısa tanıtımı gösterir,
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

  /// Firestore'daki ilk veri yüklemesinin durumu. Bu tamamlanmadan
  /// RootScreen (ve dolayısıyla ClientService()/CaseService() çağıran hiçbir
  /// ekran) gösterilmiyor - aksi halde ekranlar boş önbellek görüp yanlışça
  /// "hiç müvekkil yok" gösterebilirdi.
  late Future<void> _dataReady;

  @override
  void initState() {
    super.initState();
    _showOnboarding = !_onboardingService.hasSeen(widget.uid);
    _dataReady = _loadInitialData();
  }

  Future<void> _loadInitialData() {
    return Future.wait([
      ClientService().ensureLoaded(),
      CaseService().ensureLoaded(),
    ]);
  }

  void _retry() {
    setState(() => _dataReady = _loadInitialData());
  }

  void _finishOnboarding() {
    _onboardingService.markSeen(widget.uid);
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _dataReady,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: LoadingState());
        }
        if (snapshot.hasError) {
          // İnternet bağlantısı yoksa/Firestore'a erişilemezse - uygulama
          // çevrimiçi çalışmayı varsayıyor (D019), o yüzden burada net bir
          // hata + "Tekrar Dene" gösteriyoruz (D014'teki "asla ekranı boş
          // kırma" deseniyle tutarlı).
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Verileriniz yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (_showOnboarding) {
          return OnboardingScreen(onDone: _finishOnboarding);
        }
        return const RootScreen();
      },
    );
  }
}
