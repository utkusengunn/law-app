import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Telefon numarası üzerinden doğrudan arama/WhatsApp mesajı başlatma
/// yardımcıları (kullanıcı talebi, 2026-09-08, backlog D015.6).
///
/// Bilinçli tercih: `canLaunchUrl` ile önceden kontrol ETMİYORUZ - Android
/// 11+ paket görünürlüğü (package visibility) kısıtlamaları yüzünden
/// `canLaunchUrl` bazı cihazlarda yanlış "false" dönebiliyor, oysa
/// `launchUrl`'nin kendisi (sistemin örtük/implicit intent çözümlemesi
/// üzerinden) yine de çalışabiliyor. Bunun yerine doğrudan `launchUrl`
/// çağrılıyor, başarısız olursa (PlatformException vb.) kullanıcıya anlaşılır
/// bir SnackBar gösteriliyor - AndroidManifest'e ekstra `<queries>` bloğu
/// eklemeye gerek kalmadan (CI her build'de android/ klasörünü sıfırdan
/// ürettiği için manifest'e elle eklenen her şeyin build workflow'una da
/// eklenmesi gerekirdi, bkz. decisions.md D003.2).
class PhoneActions {
  PhoneActions._();

  static Future<void> call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.trim());
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) _showError(context, 'Arama başlatılamadı.');
    } catch (_) {
      if (context.mounted) _showError(context, 'Arama başlatılamadı.');
    }
  }

  /// wa.me formatı ülke kodu + numara ister (boşluk/parantez/+ olmadan).
  /// Basit bir sezgisel dönüşüm: Türkiye'de yazılan "0" ile başlayan 11
  /// haneli numaralar "90" ülke koduyla değiştirilir. Numara zaten "90" ile
  /// başlıyorsa dokunulmaz. Bu KESIN bir doğrulama değil - farklı ülke
  /// numaraları için kullanıcı numarayı zaten ülke koduyla girmiş olmalı.
  static String _normalizeForWhatsapp(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      return '90${digits.substring(1)}';
    }
    return digits;
  }

  static Future<void> whatsapp(BuildContext context, String phone) async {
    final normalized = _normalizeForWhatsapp(phone);
    final uri = Uri.parse('https://wa.me/$normalized');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context, 'WhatsApp açılamadı.');
      }
    } catch (_) {
      if (context.mounted) _showError(context, 'WhatsApp açılamadı.');
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
