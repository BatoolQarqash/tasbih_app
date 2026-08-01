import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _darkGreen = Color(0xFF1B4332);

// بيعرض قبل طلب صلاحية النظام مباشرة، لشرح سبب الحاجة للإشعارات؛ بيرجع true
// إذا المستخدم وافق على المتابعة (وبعدها لسا لازم يظهر طلب صلاحية النظام الفعلي)
Future<bool> showNotificationPermissionRationale(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'تفعيل تذكير الأذكار',
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _darkGreen),
      ),
      content: Text(
        'حتى نذكّرك بأذكار الصباح والمساء بوقتها، نحتاج نطلب صلاحية إظهار الإشعارات على جهازك.',
        style: GoogleFonts.cairo(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('ليس الآن', style: GoogleFonts.cairo()),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _darkGreen, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('متابعة', style: GoogleFonts.cairo()),
        ),
      ],
    ),
  );
  return result ?? false;
}
