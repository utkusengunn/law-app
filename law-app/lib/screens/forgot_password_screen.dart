import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';

/// Şifre sıfırlama bağlantısı gönderme ekranı.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorText;
  String? _successText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
      _successText = null;
    });
    try {
      await _authService.sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) {
        setState(() =>
            _successText = 'E-posta adresine bir şifre sıfırlama bağlantısı gönderildi.');
      }
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
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
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
                  const Text(
                    'Kayıtlı e-posta adresinizi girin, size bir şifre '
                    'sıfırlama bağlantısı gönderelim.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.requiredEmail,
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  if (_successText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _successText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _sendResetLink,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sıfırlama Bağlantısı Gönder'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Girişe geri dön'),
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
