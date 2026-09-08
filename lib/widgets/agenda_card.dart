import 'package:flutter/material.dart';

import '../utils/event_style.dart';

/// Ana sayfadaki "Bugün" ve "Yaklaşanlar" bölümlerinde kullanılan, etkinlik
/// türünü ilk bakışta belli eden kompakt kart.
///
/// Kullanıcı kartın üstündeki türe (Duruşma/Görüşme/İş/Süre/Ödeme) bakarak
/// "bu neydi?" diye düşünmeden anlayabilmeli - bu yüzden tür etiketi + ikon
/// her zaman en üstte, renkli ve belirgin.
class AgendaCard extends StatelessWidget {
  const AgendaCard({
    super.key,
    required this.type,
    required this.timeLabel,
    this.personLine,
    this.detailLine,
    this.onTap,
    this.dismissKey,
    this.onComplete,
  });

  final AppEventType type;

  /// Örn. "10:30" (Bugün) veya "12 Eylül · 10:30" (Yaklaşanlar).
  final String timeLabel;

  /// İlgili kişi/müvekkil ya da (İş için) kısa başlık.
  final String? personLine;

  /// Dosya bilgisi / kısa açıklama.
  final String? detailLine;

  final VoidCallback? onTap;

  /// [onComplete] doluysa bu ZORUNLU - Dismissible'ın kendi key'i, kayıt
  /// başına benzersiz olmalı (bkz. AgendaEntryData.id).
  final Key? dismissKey;

  /// Doluysa kart sağa doğru kaydırılarak (yana kaydırma) tek dokunuşla
  /// tamamlandı işaretlenebilir (kullanıcı talebi, 2026-09-08, backlog
  /// D015.5) - detay ekranına gitmeye gerek kalmaz. Şu an sadece İş ve
  /// Tevkil türlerinde doluyor (bkz. agenda_builder.dart).
  final Future<void> Function()? onComplete;

  @override
  Widget build(BuildContext context) {
    final color = EventStyle.colorFor(type);
    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 46,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(EventStyle.iconFor(type), size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          EventStyle.labelFor(type),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (personLine != null && personLine!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        personLine!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (detailLine != null && detailLine!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detailLine!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );

    if (onComplete == null) return card;

    // Yana kaydırma: yeni bir paket eklemeden (flutter_slidable vb.)
    // Flutter'ın kendi Dismissible'ı kullanılıyor - confirmDismiss'te
    // gerçek işlemi yapıp HER ZAMAN false döndürüyoruz, böylece kart
    // fiziksel olarak listeden silinmiyor (Dismissible kendi başına
    // kaldırmıyor); veri değiştiği için ekranı yenileyen taraf (home/
    // calendar ekranı) zaten kartı listeden düşürüyor.
    return Dismissible(
      key: dismissKey ?? ValueKey(personLine ?? timeLabel),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Tamamlandı',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await onComplete!();
        return false;
      },
      child: card,
    );
  }
}
