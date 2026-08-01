import 'package:flutter_riverpod/legacy.dart';
import '../models/achievement.dart';
import '../services/stats_service.dart' as stats_service;

class AchievementsState {
  const AchievementsState({required this.unlocked, required this.unlockQueue});

  final Set<AchievementId> unlocked;
  // إنجازات فتحت ولسا ما انعرض احتفالها بالواجهة (قد يفتح أكتر من واحد بنفس الضغطة)
  final List<AchievementId> unlockQueue;

  AchievementsState copyWith({
    Set<AchievementId>? unlocked,
    List<AchievementId>? unlockQueue,
  }) {
    return AchievementsState(
      unlocked: unlocked ?? this.unlocked,
      unlockQueue: unlockQueue ?? this.unlockQueue,
    );
  }
}

AchievementId? _achievementIdFromName(String name) {
  for (final id in AchievementId.values) {
    if (id.name == name) return id;
  }
  return null;
}

// StateNotifier بيدير الإنجازات المفتوحة + الحفظ التلقائي؛ الفحص idempotent
// (مرتبط فقط بـ state.unlocked بالذاكرة) عشان ما ينفتح نفس الإنجاز مرتين
class AchievementsNotifier extends StateNotifier<AchievementsState> {
  AchievementsNotifier() : super(const AchievementsState(unlocked: {}, unlockQueue: [])) {
    _load();
  }

  Future<void> _load() async {
    final names = await stats_service.loadUnlockedAchievementNames();
    final unlocked = <AchievementId>{};
    for (final name in names) {
      final id = _achievementIdFromName(name);
      if (id != null) unlocked.add(id);
    }
    state = state.copyWith(unlocked: unlocked);
  }

  // بيفحص شروط إنجازات المجموع والسلسلة، ويفتح الجديد منها فقط
  Future<void> evaluate({required int total, required int streak}) async {
    final newlyUnlocked = <AchievementId>[];

    void check(AchievementId id, bool condition) {
      if (condition && !state.unlocked.contains(id)) newlyUnlocked.add(id);
    }

    check(AchievementId.total100, total >= 100);
    check(AchievementId.total1000, total >= 1000);
    check(AchievementId.total10000, total >= 10000);
    check(AchievementId.total100000, total >= 100000);
    check(AchievementId.streak3, streak >= 3);
    check(AchievementId.streak7, streak >= 7);
    check(AchievementId.streak30, streak >= 30);
    check(AchievementId.streak100, streak >= 100);

    if (newlyUnlocked.isEmpty) return;
    await _unlockAll(newlyUnlocked);
  }

  // لأول مرة تكتمل فيها جلسة أذكار صباح/مساء
  Future<void> unlockIfFirst(AchievementId id) async {
    if (state.unlocked.contains(id)) return;
    await _unlockAll([id]);
  }

  Future<void> _unlockAll(List<AchievementId> ids) async {
    final updatedUnlocked = {...state.unlocked, ...ids};
    final updatedQueue = [...state.unlockQueue, ...ids];
    state = state.copyWith(unlocked: updatedUnlocked, unlockQueue: updatedQueue);
    await stats_service.saveUnlockedAchievementNames(
      updatedUnlocked.map((id) => id.name).toSet(),
    );
  }

  // الشاشة بتنادي هاي بعد ما تعرض احتفال أول عنصر بالطابور، لتنتقل للي بعده
  void consumeNextUnlock() {
    if (state.unlockQueue.isEmpty) return;
    state = state.copyWith(unlockQueue: state.unlockQueue.sublist(1));
  }
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  return AchievementsNotifier();
});
