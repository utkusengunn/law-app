import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Giriş ekranı. Başarılı girişte [AuthGate] otomatik olarak kök ekrana
/// geçer, bu yüzden burada ayrıca yönlendirme yapılmaz.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      await _authService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Başarılı girişte AuthGate akışı üstlenir.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorText = 'Bir hata oluştu, lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel,
                      size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Avukat Asistan',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.requiredEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) => Validators.requiredField(v, fieldName: 'Şifre'),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _signIn,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Giriş Yap'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                    child: const Text('Şifremi Unuttum'),
                  ),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                    child: const Text('Hesabınız yok mu? Kayıt olun'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
