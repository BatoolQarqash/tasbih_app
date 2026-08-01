
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

  // المجموع الكلي محفوظ بالذاكرة كمصدر وحيد للحقيقة أثناء الجلسة، وما منعيد
  // قراءته من SharedPreferences قبل كل كتابة؛ لو عملنا هيك، ضغطتين متسارعتين
  // ممكن يقرؤوا نفس القيمة القديمة ويكتبوا فوق بعض فيضيع عدّ (lost update)
  int _totalCount = 0;
  bool _totalLoaded = false;

  int get totalCount => _totalCount;

  Future<void> _loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('counter') ?? 0;
    _totalCount = prefs.getInt('total_count') ?? 0;
    _totalLoaded = true;
  }

  Future<void> increment() async {
    state++;

    // منزيد المجموع بالذاكرة قبل أي await، عشان لو استدعى الكولر increment()
    // بدون ما ينتظرها (زي ما بيصير بزر التسبيح)، القيمة تنعكس فوراً بشكل
    // متزامن قبل ما يقرا totalCount بعدها بنفس اللحظة
    if (_totalLoaded) {
      _totalCount++;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', state);

    if (!_totalLoaded) {
      _totalCount = (prefs.getInt('total_count') ?? 0) + 1;
      _totalLoaded = true;
    }
    await prefs.setInt('total_count', _totalCount);
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

// Provider منفصل للمجموع الكلي (نعرضه بالإحصائيات)؛ بيتزامن تلقائياً مع
// counterProvider لأن الاثنين بيتحدّثوا سوا جوا CounterNotifier.increment()
final totalCountProvider = Provider<int>((ref) {
  ref.watch(counterProvider);
  return ref.read(counterProvider.notifier).totalCount;
});