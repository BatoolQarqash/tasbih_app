import 'dhikr_item.dart';

enum AdhkarType { morning, evening }

extension AdhkarTypeX on AdhkarType {
  // يستخدم كـ payload بالإشعار ومفتاح تخزين
  String get storageKey => switch (this) {
        AdhkarType.morning => 'morning',
        AdhkarType.evening => 'evening',
      };

  String get titleAr => switch (this) {
        AdhkarType.morning => 'أذكار الصباح',
        AdhkarType.evening => 'أذكار المساء',
      };
}

class AdhkarSessionData {
  const AdhkarSessionData({required this.type, required this.items});

  final AdhkarType type;
  final List<DhikrItem> items;
}
