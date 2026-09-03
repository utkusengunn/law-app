import 'package:hive/hive.dart';

import 'box_names.dart';

/// İlk girişte gösterilen kısa tanıtım (onboarding) ekranının kullanıcı
/// bazında bir daha gösterilmemesi için tek bir bayrak tutar. Cihaz yerelinde
/// tutulur (Hive) - hesap değişse de kaydı ayrı tutmak için uid ile anahtarlanır.
class OnboardingService {
  Box get _box => Hive.box(BoxNames.settings);

  static String _key(String uid) => 'onboarding_seen_$uid';

  bool hasSeen(String uid) => (_box.get(_key(uid)) as bool?) ?? false;

  Future<void> markSeen(String uid) => _box.put(_key(uid), true);
}
