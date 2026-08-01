import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/adhkar_data.dart';
import '../models/achievement.dart';
import '../models/adhkar_session.dart';
import '../models/dhikr_item.dart';
import '../services/stats_service.dart' as stats_service;
import 'achievements_provider.dart';
import 'stats_provider.dart';

class AdhkarSessionState {
  const AdhkarSessionState({
    required this.currentIndex,
    required this.currentItemTapCount,
    required this.completed,
  });

  const AdhkarSessionState.initial()
      : currentIndex = 0,
        currentItemTapCount = 0,
        completed = false;

  final int currentIndex;
  final int currentItemTapCount;
  final bool completed;

  AdhkarSessionState copyWith({
    int? currentIndex,
    int? currentItemTapCount,
    bool? completed,
  }) {
    return AdhkarSessionState(
      currentIndex: currentIndex ?? this.currentIndex,
      currentItemTapCount: currentItemTapCount ?? this.currentItemTapCount,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentIndex': currentIndex,
        'currentItemTapCount': currentItemTapCount,
        'completed': completed,
      };

  static AdhkarSessionState fromJson(Map<String, dynamic> json) {
    return AdhkarSessionState(
      currentIndex: json['currentIndex'] as int,
      currentItemTapCount: json['currentItemTapCount'] as int,
      completed: json['completed'] as bool,
    );
  }
}

// StateNotifier بيدير تقدّم جلسة أذكار الصباح أو المساء + استئنافها لنفس
// اليوم + تسجيل كل ضغطة بالإحصائيات العامة (حتى يوم أذكار فقط بدون تسبيح حر
// يُحتسب نشاط لأغراض السلسلة والإحصائيات)
class AdhkarSessionNotifier extends StateNotifier<AdhkarSessionState> {
  AdhkarSessionNotifier(this._ref, this.type) : super(const AdhkarSessionState.initial()) {
    _load();
  }

  final Ref _ref;
  final AdhkarType type;

  List<DhikrItem> get items => adhkarSessions[type]!.items;

  Future<void> _load() async {
    final saved = await stats_service.loadAdhkarSessionProgress(type.storageKey);
    if (saved != null) {
      state = AdhkarSessionState.fromJson(saved);
    }
  }

  DhikrItem get currentItem => items[state.currentIndex];

  // بيسجّل ضغطة على الذكر الحالي، وبينتقل تلقائياً للي بعده لما يوصل الهدف
  void tap() {
    if (state.completed) return;

    _ref.read(statsProvider.notifier).recordTap();

    final newTapCount = state.currentItemTapCount + 1;

    if (newTapCount >= currentItem.targetCount) {
      final isLastItem = state.currentIndex >= items.length - 1;
      if (isLastItem) {
        state = state.copyWith(currentItemTapCount: newTapCount, completed: true);
        _onSessionCompleted();
      } else {
        state = AdhkarSessionState(
          currentIndex: state.currentIndex + 1,
          currentItemTapCount: 0,
          completed: false,
        );
      }
    } else {
      state = state.copyWith(currentItemTapCount: newTapCount);
    }

    _persist();
  }

  void _onSessionCompleted() {
    final achievementId = type == AdhkarType.morning
        ? AchievementId.firstMorningAdhkar
        : AchievementId.firstEveningAdhkar;
    _ref.read(achievementsProvider.notifier).unlockIfFirst(achievementId);
  }

  Future<void> _persist() async {
    await stats_service.saveAdhkarSessionProgress(type.storageKey, state.toJson());
  }
}

final adhkarSessionMorningProvider =
    StateNotifierProvider<AdhkarSessionNotifier, AdhkarSessionState>((ref) {
  return AdhkarSessionNotifier(ref, AdhkarType.morning);
});

final adhkarSessionEveningProvider =
    StateNotifierProvider<AdhkarSessionNotifier, AdhkarSessionState>((ref) {
  return AdhkarSessionNotifier(ref, AdhkarType.evening);
});
