import 'package:hive/hive.dart';

/// Tevkil işinin hangi tür işlemden doğduğu - kendi işlerimizden farklı
/// olarak burada duruşma/görüşme/iş üçünden HANGİSİ olacağı önceden belli
/// olmayabilir, bu yüzden ayrı bir kayıt türü olarak tutuluyor (kullanıcı
/// talebi, 2026-09-08). İsimler diğer enum'larla (HearingStatus,
/// MeetingStatus vb.) tutarlı olsun diye İngilizce - Türkçe karşılıkları
/// EnumLabels.tevkilAltTuru() üzerinden gösterilir. NOT: Dart enum
/// değerleri sadece ASCII olabilir, bu yüzden "duruşma/görüşme/iş" gibi
/// Türkçe karakterli isimler burada KULLANILAMAZ.
///
/// [other] (Diğer) kullanıcı talebiyle eklendi (2026-09-08, backlog D015.1)
/// - sabit üç türe uymayan tevkil işleri için. LİSTENİN SONUNA eklendi: Hive
/// bu enum'u index (sıra numarası) olarak sakladığı için var olan
/// kayıtlardaki 0/1/2 (hearing/meeting/task) hiç değişmemeli.
enum TevkilAltTuru { hearing, meeting, task, other }

/// Tevkil işinin durumu - Hearing/Meeting'deki status alanlarıyla aynı
/// mantık: sadece manuel işaretleme için saklanır, ayrıca hesaplanan bir
/// "gecikmiş" durumu yok (md.5'teki ödeme gibi otomatik hesaplama burada
/// gerekmiyor - bu bir iş takip kaydı, ödeme değil).
enum TevkilDurum { pending, completed, cancelled }

/// Bir meslektaştan/büyürden tevkil (vekaleten) alınan iş kaydı. Kendi
/// işlerimizden (Hearing/Meeting/LegalTask) BİLİNÇLİ olarak ayrı bir model:
/// tevkil işi duruşma da olabilir, görüşme de, iş de - [altTur] bunu
/// belirtir. Dosya/müvekkil bağlantısı OPSİYONELDİR - çoğu tevkil işinin
/// kendi dosyamız/müvekkilimiz yoktur, sadece bazen (örn. kendi
/// müvekkilimize ait bir dosyada başka bir avukattan tevkil aldığımızda)
/// bağlı olabilir.
class TevkilIsi extends HiveObject {
  TevkilIsi({
    required this.id,
    required this.altTur,
    required this.tarih,
    this.tumGun = false,
    required this.baslik,
    required this.tevkilEdenAd,
    this.tevkilEdenIletisim,
    this.caseId,
    this.clientId,
    this.note,
    this.durum = TevkilDurum.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  String id;
  TevkilAltTuru altTur;
  DateTime tarih;

  /// Duruşma/görüşme genelde saatli olur, iş türü çoğu zaman tüm gün -
  /// ajanda kartında saat mi "Tüm gün" mü gösterileceğini belirler (bkz.
  /// AgendaEntryData.hasTime, home_screen/calendar_screen'deki diğer
  /// türlerle aynı mantık).
  bool tumGun;

  /// Kısa başlık - örn. "İcra takibine itiraz duruşması" ya da "Tebligat
  /// takibi". Duruşma/görüşme türünde mahkeme/konu, iş türünde iş adı olur.
  String baslik;

  String tevkilEdenAd;
  String? tevkilEdenIletisim;

  /// İkisi de opsiyonel - bazen bağlı bir dosyamız/müvekkilimiz olur, çoğu
  /// zaman olmaz (kullanıcı talebi: "bazen bağlı, bazen değil").
  String? caseId;
  String? clientId;

  String? note;
  TevkilDurum durum;
  DateTime createdAt;
  DateTime updatedAt;

  TevkilIsi copyWith({
    TevkilAltTuru? altTur,
    DateTime? tarih,
    bool? tumGun,
    String? baslik,
    String? tevkilEdenAd,
    String? tevkilEdenIletisim,
    String? caseId,
    String? clientId,
    String? note,
    TevkilDurum? durum,
    DateTime? updatedAt,
  }) {
    return TevkilIsi(
      id: id,
      altTur: altTur ?? this.altTur,
      tarih: tarih ?? this.tarih,
      tumGun: tumGun ?? this.tumGun,
      baslik: baslik ?? this.baslik,
      tevkilEdenAd: tevkilEdenAd ?? this.tevkilEdenAd,
      tevkilEdenIletisim: tevkilEdenIletisim ?? this.tevkilEdenIletisim,
      caseId: caseId ?? this.caseId,
      clientId: clientId ?? this.clientId,
      note: note ?? this.note,
      durum: durum ?? this.durum,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TevkilIsiAdapter extends TypeAdapter<TevkilIsi> {
  // typeId 0-7 mevcut 8 modelde kullanılıyor (bkz. hive_registrar.dart),
  // 8 burada ilk defa kullanılıyor - çakışma yok.
  @override
  final int typeId = 8;

  @override
  TevkilIsi read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TevkilIsi(
      id: fields[0] as String,
      altTur: TevkilAltTuru.values[fields[1] as int],
      tarih: fields[2] as DateTime,
      tumGun: (fields[3] as bool?) ?? false,
      baslik: fields[4] as String,
      tevkilEdenAd: fields[5] as String,
      tevkilEdenIletisim: fields[6] as String?,
      caseId: fields[7] as String?,
      clientId: fields[8] as String?,
      note: fields[9] as String?,
      durum: TevkilDurum.values[fields[10] as int],
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TevkilIsi obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.altTur.index)
      ..writeByte(2)
      ..write(obj.tarih)
      ..writeByte(3)
      ..write(obj.tumGun)
      ..writeByte(4)
      ..write(obj.baslik)
      ..writeByte(5)
      ..write(obj.tevkilEdenAd)
      ..writeByte(6)
      ..write(obj.tevkilEdenIletisim)
      ..writeByte(7)
      ..write(obj.caseId)
      ..writeByte(8)
      ..write(obj.clientId)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.durum.index)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TevkilIsiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
