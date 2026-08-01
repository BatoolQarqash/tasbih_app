import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tasbih_app/screens/splash_screen.dart';
import 'screens/adhkar_session_screen.dart';
import 'services/notification_service.dart';

// مفتاح تنقّل عام حتى نقدر نفتح شاشة جلسة الأذكار من كولباك الإشعار مباشرة،
// بغض النظر عن الشاشة اللي المستخدم واقف فيها حالياً
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob ما بيشتغل على الويب، فقط نشغله على أندرويد/iOS
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // نهيّئ خدمة الإشعارات بدري قبل runApp، عشان: (1) نلغي التذكير العام
  // القديم المُلغى من التطبيق، و(2) نلتقط أي ضغطة إشعار فتحت التطبيق من
  // الصفر (cold start) قبل ما تبني أي شاشة
  NotificationService.instance.onAdhkarNotificationTap = (type) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => AdhkarSessionScreen(type: type)),
    );
  };
  await NotificationService.instance.init();

  runApp(
    const ProviderScope(
      child: TasbihApp(),
    ),
  );
}

class TasbihApp extends StatelessWidget {
  const TasbihApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'عداد التسبيح',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        textTheme: GoogleFonts.cairoTextTheme(),
      ),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
