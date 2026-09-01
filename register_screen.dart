import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';

/// Kayıt ekranı. Başarılı kayıtta [AuthGate] otomatik olarak kök ekrana
/// geçer, bu yüzden burada ayrıca yönlendirme yapılmaz.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      await _authService.register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _fullNameCtrl.text.trim(),
      );
      // Başarılı kayıtta AuthGate akışı üstlenir.
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
      appBar: AppBar(title: const Text('Kayıt Ol')),
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
                  TextFormField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(labelText: 'Ad Soyad'),
                    validator: (v) =>
                        Validators.requiredField(v, fieldName: 'Ad soyad'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.requiredEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    obscureText: true,
                    validator: Validators.requiredPassword,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Şifre (Tekrar)'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Şifre tekrarı zorunludur.';
                      }
                      if (v != _passwordCtrl.text) {
                        return 'Şifreler eşleşmiyor.';
                      }
                      return null;
                    },
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
                    onPressed: _submitting ? null : _register,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Kayıt Ol'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Zaten hesabınız var mı? Giriş yapın'),
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
