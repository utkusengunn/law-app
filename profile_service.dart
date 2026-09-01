import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore profil işlemleri sırasında oluşan hataları kullanıcıya
/// gösterilebilir, Türkçe bir mesaja dönüştüren basit istisna tipi.
class ProfileFailure implements Exception {
  ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// `users/{uid}` koleksiyonundaki avukat profil belgesi üzerine ince bir
/// sarmalayıcı.
class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'users';
  static const _genericMessage = 'Bir hata oluştu, lütfen tekrar deneyin.';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_collection);

  Future<void> createInitialProfile({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _users.doc(uid).set({
        'fullName': fullName,
        'email': email,
        'phone': null,
        'firmName': null,
        'createdAt': now,
        'updatedAt': now,
      });
    } catch (_) {
      throw ProfileFailure(_genericMessage);
    }
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    try {
      final snapshot = await _users.doc(uid).get();
      return snapshot.data();
    } catch (_) {
      throw ProfileFailure(_genericMessage);
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? firmName,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (fullName != null) data['fullName'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (firmName != null) data['firmName'] = firmName;

      await _users.doc(uid).update(data);
    } catch (_) {
      throw ProfileFailure(_genericMessage);
    }
  }
}
