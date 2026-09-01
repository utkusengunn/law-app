# Avukat Asistan

Avukat Asistan, bireysel çalışan avukatlar için geliştirilen, dava/dosya ve müvekkil takibini kolaylaştıran bir mobil uygulamadır. Bu sürüm (v0.1), tamamen çevrimdışı ve tek kullanıcılı bir iskelet olarak çalışır: müvekkil, dosya, duruşma, süre, görüşme, iş ve ödeme kayıtlarını cihaz üzerinde (Hive veritabanı ile) saklar. Amaç, avukatın gününe hızlıca hakim olabileceği sade bir kontrol merkezi sunmaktır — dashboard ekranı bugünün ve önümüzdeki 7 günün duruşma/görüşme/iş/süre/ödeme kayıtlarını tek bakışta gösterir.

## Nasıl Çalıştırılır

**Yerel geliştirme:** Flutter SDK kurulu bir makinede proje klasöründe `flutter pub get` ile bağımlılıkları indirin, ardından bağlı bir Android cihaz/emülatörde `flutter run` ile uygulamayı başlatın.

**APK indirme:** Bu depoya `main` dalına her push yapıldığında GitHub Actions otomatik olarak release APK'sı üretir. Depodaki **Actions** sekmesinden ilgili iş akışını (workflow) açıp tamamlanan çalıştırmanın **Artifacts** bölümünden `law-app-release` adlı dosyayı indirebilirsiniz. İş akışı `workflow_dispatch` ile elle de tetiklenebilir.

## v0.1 Kapsamı

Bu sürümde müvekkil, dosya, duruşma, süre, görüşme, iş ve ödeme yönetimi; arama/filtreleme; takvim görünümü ve günlük/haftalık özet ekranı yer alır. Müvekkil ve dosya kayıtları asla kalıcı olarak silinmez — "pasif" veya "kapalı" duruma alınarak bağlı tüm kayıtlar (dosya, görüşme, ödeme, süre) korunur.

## Bilinen Sınırlar

v0.1'de backend, kullanıcı hesabı/kimlik doğrulama (auth) ve push bildirimleri **yoktur**. Tüm veriler yalnızca cihazda tutulur; uygulama silinirse veya cihaz değişirse veriler taşınmaz. Süre hatırlatmaları şu an sadece uygulama içinde görüntülenir, bildirim olarak gönderilmez. Bu özellikler (çoklu cihaz senkronizasyonu, giriş ekranı, push bildirimleri) Firebase entegrasyonu ile birlikte v0.2'de eklenmesi planlanmaktadır.
