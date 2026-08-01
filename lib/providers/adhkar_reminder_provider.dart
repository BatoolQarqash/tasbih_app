import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adhkar_session.dart';
import '../services/notification_service.dart';

class AdhkarReminderSettings {
  const AdhkarReminderSettings({
    required this.morningEnabled,
    required this.morningHour,
    required this.morningMinute,
    required this.eveningEnabled,
    required this.eveningHour,
    required this.eveningMinute,
  });

  final bool morningEnabled;
  final int morningHour;
  final int morningMinute;
  final bool eveningEnabled;
  final int eveningHour;
  final int eveningMinute;

  AdhkarReminderSettings copyWith({
    bool? morningEnabled,
    int? morningHour,
    int? morningMinute,
    bool? eveningEnabled,
    int? eveningHour,
    int? eveningMinute,
  }) {
    return AdhkarReminderSettings(
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      eveningHour: eveningHour ?? this.eveningHour,
      eveningMinute: eveningMinute ?? this.eveningMinute,
    );
  }
}

// StateNotifier بيدير إعدادات تذكيري أذكار الصباح والمساء (كل وحدة مستقلة
// عن التانية) + الحفظ التلقائي + جدولة/إلغاء الإشعارات المرتبطة
class AdhkarReminderNotifier extends StateNotifier<AdhkarReminderSettings> {
  AdhkarReminderNotifier()
      : super(
          const AdhkarReminderSettings(
            morningEnabled: false,
            morningHour: 6,
            morningMinute: 0,
            eveningEnabled: false,
            eveningHour: 17,
            eveningMinute: 0,
          ),
        ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = AdhkarReminderSettings(
      morningEnabled: prefs.getBool('adhkar_morning_enabled') ?? false,
      morningHour: prefs.getInt('adhkar_morning_hour') ?? 6,
      morningMinute: prefs.getInt('adhkar_morning_minute') ?? 0,
      eveningEnabled: prefs.getBool('adhkar_evening_enabled') ?? false,
      eveningHour: prefs.getInt('adhkar_evening_hour') ?? 17,
      eveningMinute: prefs.getInt('adhkar_evening_minute') ?? 0,
    );
    state = loaded;

    await NotificationService.instance.init();
    if (loaded.morningEnabled) {
      await NotificationService.instance.scheduleAdhkarReminder(
        type: AdhkarType.morning,
        hour: loaded.morningHour,
        minute: loaded.morningMinute,
      );
    }
    if (loaded.eveningEnabled) {
      await NotificationService.instance.scheduleAdhkarReminder(
        type: AdhkarType.evening,
        hour: loaded.eveningHour,
        minute: loaded.eveningMinute,
      );
    }
  }

  // بيحاول يفعّل/يعدّل تذكير الصباح، وبيرجع false إذا رفض المستخدم صلاحية الإشعارات
  Future<bool> setMorningReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final granted = await _applyReminder(AdhkarType.morning, enabled, hour, minute);
    if (!granted) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhkar_morning_enabled', enabled);
    await prefs.setInt('adhkar_morning_hour', hour);
    await prefs.setInt('adhkar_morning_minute', minute);

    state = state.copyWith(morningEnabled: enabled, morningHour: hour, morningMinute: minute);
    return true;
  }

  Future<bool> setEveningReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final granted = await _applyReminder(AdhkarType.evening, enabled, hour, minute);
    if (!granted) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhkar_evening_enabled', enabled);
    await prefs.setInt('adhkar_evening_hour', hour);
    await prefs.setInt('adhkar_evening_minute', minute);

    state = state.copyWith(eveningEnabled: enabled, eveningHour: hour, eveningMinute: minute);
    return true;
  }

  Future<bool> _applyReminder(AdhkarType type, bool enabled, int hour, int minute) async {
    await NotificationService.instance.init();

    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return false;
      await NotificationService.instance.scheduleAdhkarReminder(type: type, hour: hour, minute: minute);
    } else {
      await NotificationService.instance.cancelAdhkarReminder(type);
    }
    return true;
  }
}

final adhkarReminderProvider =
    StateNotifierProvider<AdhkarReminderNotifier, AdhkarReminderSettings>((ref) {
  return AdhkarReminderNotifier();
});
