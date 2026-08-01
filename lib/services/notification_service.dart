import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/adhkar_session.dart';

// خدمة الإشعارات: تهيئة المكتبة + طلب الصلاحية + جدولة/إلغاء تذكيري أذكار
// الصباح والمساء + التعامل مع الضغط على الإشعار لفتح جلسة الأذكار المناسبة
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int _morningReminderId = 2001;
  static const int _eveningReminderId = 2002;

  // معرّف التذكير العام القديم (المُلغى من التطبيق)؛ لازم نُلغيه صراحة
  // عشان ما يضل يشتغل بالخلفية عند المستخدمين اللي كانوا مفعّلينه بنسخة سابقة،
  // لأنه مجدول بوضع "يتجدد تلقائياً" وما بينلغي لمجرد حذف الكود المسؤول عنه
  static const int _legacyGenericReminderId = 1001;

  bool _initialized = false;

  // يوصل هذا الكولباك من main.dart، وينفّذ لما ينضغط إشعار والتطبيق شغال
  // (foreground أو background) - مو عند الإقلاع البارد
  void Function(AdhkarType type)? onAdhkarNotificationTap;

  // لو التطبيق انفتح لأول مرة بضغطة على إشعار وهو مقفول تماماً (cold start)،
  // بينخزن هون النوع المطلوب فتحه؛ الشاشة الرئيسية بتقرأه مرة وحدة بس
  // بعد أول frame وتصفّره
  AdhkarType? pendingAdhkarLaunchType;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // إذا فشل تحديد المنطقة الزمنية، نكمل بالإعداد الافتراضي بدل ما نوقف التطبيق
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // ترحيل: إلغاء غير مشروط للتذكير العام القديم (راجع التعليق فوق)
    await _plugin.cancel(id: _legacyGenericReminderId);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      pendingAdhkarLaunchType = _typeFromPayload(launchDetails?.notificationResponse?.payload);
    }

    _initialized = true;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final type = _typeFromPayload(response.payload);
    if (type != null) onAdhkarNotificationTap?.call(type);
  }

  AdhkarType? _typeFromPayload(String? payload) {
    switch (payload) {
      case 'morning':
        return AdhkarType.morning;
      case 'evening':
        return AdhkarType.evening;
      default:
        return null;
    }
  }

  // بيرجع true إذا انعطت الصلاحية، false إذا رفضها المستخدم
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  // مقصودة inexactAllowWhileIdle (بدون صلاحية المنبّه الدقيق): تذكير الأذكار
  // إرشادي مو حرج التوقيت، وطلب صلاحية "SCHEDULE_EXACT_ALARM" ممكن يعرّض
  // نشر التطبيق على Play Console لمراجعة إضافية بلا فائدة حقيقية تذكر هون
  Future<void> scheduleAdhkarReminder({
    required AdhkarType type,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    final id = type == AdhkarType.morning ? _morningReminderId : _eveningReminderId;
    final title = type.titleAr;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: 'حان وقت الأذكار 🌿',
      payload: type.storageKey,
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhkar_reminder_channel',
          'تذكير الأذكار',
          channelDescription: 'تذكير يومي بأذكار الصباح والمساء',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAdhkarReminder(AdhkarType type) async {
    if (kIsWeb) return;
    final id = type == AdhkarType.morning ? _morningReminderId : _eveningReminderId;
    await _plugin.cancel(id: id);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
