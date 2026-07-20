import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// نصوص جاهزة يختار منها المستخدم لرسالة التذكير اليومي
const List<String> reminderMessages = [
  'حان وقت الذكر 🌿',
  'لا تنسَ نصيبك من الذكر اليوم 🤍',
  'دقيقة تسبيح تنوّر يومك ✨',
  'اذكر الله يذكرك 🌙',
];

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.message,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final String message;

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    String? message,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      message: message ?? this.message,
    );
  }
}

// StateNotifier بيدير إعدادات التذكير اليومي + الحفظ التلقائي + جدولة الإشعار
class ReminderNotifier extends StateNotifier<ReminderSettings> {
  ReminderNotifier()
      : super(
          ReminderSettings(
            enabled: false,
            hour: 8,
            minute: 0,
            message: reminderMessages[0],
          ),
        ) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminder_enabled') ?? false;
    final hour = prefs.getInt('reminder_hour') ?? 8;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    final message = prefs.getString('reminder_message') ?? reminderMessages.first;

    state = ReminderSettings(
      enabled: enabled,
      hour: hour,
      minute: minute,
      message: message,
    );

    if (enabled) {
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleDaily(
        hour: hour,
        minute: minute,
        message: message,
      );
    }
  }

  // بيحاول يفعّل التذكير، وبيرجع false إذا رفض المستخدم صلاحية الإشعارات
  Future<bool> setReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required String message,
  }) async {
    await NotificationService.instance.init();

    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        return false;
      }
      await NotificationService.instance.scheduleDaily(
        hour: hour,
        minute: minute,
        message: message,
      );
    } else {
      await NotificationService.instance.cancelDaily();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    await prefs.setString('reminder_message', message);

    state = ReminderSettings(
      enabled: enabled,
      hour: hour,
      minute: minute,
      message: message,
    );
    return true;
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderSettings>((ref) {
  return ReminderNotifier();
});
