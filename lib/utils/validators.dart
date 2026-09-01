/// Form alanları için ortak doğrulama (validation) fonksiyonları.
/// Tüm hata mesajları kullanıcıya gösterilmek üzere Türkçe yazılmıştır.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$');

  static String? requiredField(String? value, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName zorunludur.';
    }
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi giriniz.';
    }
    return null;
  }

  static String? requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta zorunludur.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi giriniz.';
    }
    return null;
  }

  static String? requiredPassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Şifre zorunludur.';
    }
    if (value.length < minLength) {
      return 'Şifre en az $minLength karakter olmalıdır.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası zorunludur.';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) {
      return 'Geçerli bir telefon numarası giriniz.';
    }
    return null;
  }

  static String? nonNegativeAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tutar zorunludur.';
    }
    final normalized = value.replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    if (amount == null) {
      return 'Geçerli bir tutar giriniz.';
    }
    if (amount < 0) {
      return 'Tutar negatif olamaz.';
    }
    return null;
  }

  /// Kapanış tarihinin açılış tarihinden önce olmadığını doğrular.
  static String? dateNotBefore(DateTime? later, DateTime? earlier,
      {String message = 'Tarih, başlangıç tarihinden önce olamaz.'}) {
    if (later == null || earlier == null) return null;
    if (later.isBefore(earlier)) {
      return message;
    }
    return null;
  }
}
