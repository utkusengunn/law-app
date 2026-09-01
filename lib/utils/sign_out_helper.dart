import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Uygulama genelinde tutarlı çıkış yapma akışı: onay diyaloğu, işlem
/// sırasında görsel geri bildirim ("Çıkış yapılıyor...") ve tekrar tekrar
/// basmayı engelleme. Hem Profilim ekranından hem de ana sayfadaki hamburger
/// menüden aynı davranış için kullanılır (md.10 tutarlılık).
class SignOutHelper {
  SignOutHelper._();

  static bool _inProgress = false;

  static Future<void> confirmAndSignOut(
    BuildContext context, {
    required AuthService authService,
  }) async {
    if (_inProgress) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet, Çıkış Yap'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    _inProgress = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Text('Çıkış yapılıyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    String? errorMessage;
    try {
      await authService.signOut();
    } on AuthFailure catch (e) {
      errorMessage = e.message;
    } finally {
      _inProgress = false;
    }

    if (!context.mounted) return;
    // Yükleniyor diyaloğunu kapat.
    Navigator.of(context, rootNavigator: true).pop();

    if (errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }
    // Başarılıysa AuthGate, oturum kapanınca otomatik olarak giriş ekranına döner.
  }
}
