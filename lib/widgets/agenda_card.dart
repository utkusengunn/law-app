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
  });

  final AppEventType type;

  /// Örn. "10:30" (Bugün) veya "12 Eylül · 10:30" (Yaklaşanlar).
  final String timeLabel;

  /// İlgili kişi/müvekkil ya da (İş için) kısa başlık.
  final String? personLine;

  /// Dosya bilgisi / kısa açıklama.
  final String? detailLine;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = EventStyle.colorFor(type);
    return Card(
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
  }
}
