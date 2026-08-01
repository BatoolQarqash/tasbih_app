// عنصر ذكر واحد جوا جلسة الأذكار (نص الذكر + العدد المطلوب + فضله اختياري)
class DhikrItem {
  const DhikrItem({
    required this.text,
    required this.targetCount,
    this.virtue,
  });

  final String text;
  final int targetCount;
  final String? virtue;
}
