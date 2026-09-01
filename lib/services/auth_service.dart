import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';

/// Kimlik doğrulama hatalarını kullanıcıya gösterilebilir, Türkçe bir
/// mesaja dönüştüren basit istisna tipi. Ham Firebase hataları/stack trace
/// hiçbir zaman arayüze sızmaz.
class AuthFailure implements Exception {
  AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// `FirebaseAuth.instance` üzerine ince bir sarmalayıcı. Kayıt sırasında
/// kullanıcının görünen adını günceller ve Firestore'da eşlik eden profil
/// belgesini oluşturur.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, ProfileService? profileService})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _profileService = profileService ?? ProfileService();

  final FirebaseAuth _auth;
  final ProfileService _profileService;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(fullName.trim());
        await _profileService.createInitialProfile(
          uid: user.uid,
          fullName: fullName.trim(),
          email: email.trim(),
        );
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    } catch (_) {
      throw AuthFailure(_genericMessage);
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    } catch (_) {
      throw AuthFailure(_genericMessage);
    }
  }

  Future<void> signOut() async {
    try {
      // FirebaseAuth.signOut() yerel olarak çalışır ama bazı Android
      // cihazlarda/ağ koşullarında dahili temizlik birkaç saniye sürebilir.
      // Kullanıcıyı süresiz bloklamamak için üst sınır koyuyoruz - zaman
      // aşımında dahi yerel oturum durumu genelde zaten temizlenmiş olur.
      await _auth.signOut().timeout(const Duration(seconds: 6));
    } on TimeoutException {
      // Sessizce devam et; authStateChanges zaten tetiklenmiş olacaktır.
    } catch (_) {
      throw AuthFailure(_genericMessage);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    } catch (_) {
      throw AuthFailure(_genericMessage);
    }
  }

  static const _genericMessage = 'Bir hata oluştu, lütfen tekrar deneyin.';

  String _messageFor(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi giriniz.';
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'user-not-found':
        return 'Bu e-posta adresine kayıtlı bir kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edip tekrar deneyin.';
      default:
        return _genericMessage;
    }
  }
}
