
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tasbihTypeProvider = StateProvider<String>((ref) => 'سبحان الله');

const List<String> tasbihOptions = [
  'سبحان الله',
  'الحمد لله',
  'الله أكبر',
  'لا إله إلا الله',
  'أستغفر الله',
  'اللهم صل على محمد',
  'لا حول ولا قوة إلا بالله',
  'حسبنا الله ونعم الوكيل',
];

// StateNotifier بيدير العداد + الحفظ التلقائي
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0) {
    _loadCount();
  }

  Future<void> _loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('counter') ?? 0;
  }

  Future<void> increment() async {
    state++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', state);

    // نحفظ كمان المجموع الكلي (كل الأذكار من أول ما نزّلت التطبيق)
    final total = prefs.getInt('total_count') ?? 0;
    await prefs.setInt('total_count', total + 1);
  }

  Future<void> reset() async {
    state = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', 0);
  }
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

// خيارات الهدف الجاهزة
const List<int> targetPresets = [33, 99, 100];

// StateNotifier بيدير الهدف المطلوب للتسبيح + الحفظ التلقائي
class TargetNotifier extends StateNotifier<int> {
  TargetNotifier() : super(33) {
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('target') ?? 33;
  }

  Future<void> setTarget(int value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target', value);
  }
}

final targetProvider = StateNotifierProvider<TargetNotifier, int>((ref) {
  return TargetNotifier();
});

// Provider منفصل للمجموع الكلي (نعرضه بالإحصائيات)
final totalCountProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('total_count') ?? 0;
});