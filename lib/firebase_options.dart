import 'package:firebase_core/firebase_core.dart';

/// Firebase Web yapılandırması (D021, 2026-09-13 - web/PWA denemesi).
///
/// Android/iOS'ta bu değerlere gerek yok (google-services.json /
/// GoogleService-Info.plist üzerinden otomatik geliyor). Web'de ise
/// tarayıcı tarafında böyle bir yerel dosya mekanizması olmadığı için
/// Firebase config'i açıkça Dart koduna gömülmesi gerekiyor.
///
/// Değerler Firebase Console'da kaydedilen "Law assistant" adlı web
/// uygulamasından alındı (2026-09-13, proje: law-app-40486). `measurementId`
/// (Firebase Analytics için) bilerek eklenmedi - bu uygulama Analytics
/// kullanmıyor.
///
/// NOT: Bu değerler (apiKey dahil) gizli bir sır DEĞİLDİR - Firebase'in web
/// SDK'sı bunları zaten tarayıcıda herkese açık şekilde taşır, güvenlik
/// Firestore Security Rules (bkz. firestore.rules) ile sağlanır.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFYSvAZrzCmC2z5X0Rg4FL1OUtUb1VYpg',
    authDomain: 'law-app-40486.firebaseapp.com',
    projectId: 'law-app-40486',
    storageBucket: 'law-app-40486.firebasestorage.app',
    messagingSenderId: '790173279451',
    appId: '1:790173279451:web:1545dbb5c0fe192291d8fe',
  );
}
