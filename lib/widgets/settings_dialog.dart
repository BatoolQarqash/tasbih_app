import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/adhkar_reminder_provider.dart';
import '../providers/counter_provider.dart';
import 'notification_permission_rationale_dialog.dart';

const _darkGreen = Color(0xFF1B4332);

// Dialog الإعدادات: اختيار هدف التسبيح + تفعيل تذكيري أذكار الصباح والمساء ووقتهما
Future<void> showSettingsDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (context) => const SettingsDialog(),
  );
}

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late int _selectedTarget;
  late bool _isCustomTarget;
  late final TextEditingController _customTargetController;

  late bool _morningEnabled;
  late TimeOfDay _morningTime;
  late bool _eveningEnabled;
  late TimeOfDay _eveningTime;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final currentTarget = ref.read(targetProvider);
    _isCustomTarget = !targetPresets.contains(currentTarget);
    _selectedTarget = currentTarget;
    _customTargetController = TextEditingController(
      text: _isCustomTarget ? currentTarget.toString() : '',
    );

    final reminders = ref.read(adhkarReminderProvider);
    _morningEnabled = reminders.morningEnabled;
    _morningTime = TimeOfDay(hour: reminders.morningHour, minute: reminders.morningMinute);
    _eveningEnabled = reminders.eveningEnabled;
    _eveningTime = TimeOfDay(hour: reminders.eveningHour, minute: reminders.eveningMinute);
  }

  @override
  void dispose() {
    _customTargetController.dispose();
    super.dispose();
  }

  int? get _resolvedTarget {
    if (!_isCustomTarget) return _selectedTarget;
    final value = int.tryParse(_customTargetController.text.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  Future<void> _pickMorningTime() async {
    final picked = await showTimePicker(context: context, initialTime: _morningTime);
    if (picked != null) setState(() => _morningTime = picked);
  }

  Future<void> _pickEveningTime() async {
    final picked = await showTimePicker(context: context, initialTime: _eveningTime);
    if (picked != null) setState(() => _eveningTime = picked);
  }

  // بيعرض شرح سبب الحاجة للإشعارات قبل ما يفعّل السويتش (قبل طلب صلاحية
  // النظام الفعلي اللي بيصير لاحقاً عند الحفظ)
  Future<void> _onToggleMorning(bool value) async {
    if (value) {
      final proceed = await showNotificationPermissionRationale(context);
      if (!proceed) return;
    }
    setState(() => _morningEnabled = value);
  }

  Future<void> _onToggleEvening(bool value) async {
    if (value) {
      final proceed = await showNotificationPermissionRationale(context);
      if (!proceed) return;
    }
    setState(() => _eveningEnabled = value);
  }

  Future<void> _save() async {
    final target = _resolvedTarget;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أدخل رقم هدف صحيح', style: GoogleFonts.cairo())),
      );
      return;
    }

    setState(() => _saving = true);

    await ref.read(targetProvider.notifier).setTarget(target);

    final morningGranted = await ref.read(adhkarReminderProvider.notifier).setMorningReminder(
          enabled: _morningEnabled,
          hour: _morningTime.hour,
          minute: _morningTime.minute,
        );
    final eveningGranted = await ref.read(adhkarReminderProvider.notifier).setEveningReminder(
          enabled: _eveningEnabled,
          hour: _eveningTime.hour,
          minute: _eveningTime.minute,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    final deniedMorning = _morningEnabled && !morningGranted;
    final deniedEvening = _eveningEnabled && !eveningGranted;

    if (deniedMorning || deniedEvening) {
      setState(() {
        if (deniedMorning) _morningEnabled = false;
        if (deniedEvening) _eveningEnabled = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('الإشعارات غير مفعّلة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text(
            'تم رفض صلاحية الإشعارات. لتفعيل تذكير الأذكار، يرجى تفعيل الإشعارات لهذا التطبيق يدوياً من إعدادات الجهاز.',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('حسناً', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      );
      return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // على التابلت أو الشاشات العريضة، منحدد أقصى عرض للـ Dialog حتى ما
    // يتمدد لحافة الشاشة؛ وعلى الهواتف الضيقة بيتقلص تلقائياً مع الشاشة
    final dialogWidth = (MediaQuery.sizeOf(context).width * 0.9).clamp(0.0, 420.0);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'الإعدادات',
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _darkGreen),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هدف التسبيح',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final preset in targetPresets)
                    ChoiceChip(
                      label: Text('$preset', style: GoogleFonts.cairo()),
                      selected: !_isCustomTarget && _selectedTarget == preset,
                      onSelected: (_) => setState(() {
                        _isCustomTarget = false;
                        _selectedTarget = preset;
                      }),
                    ),
                  ChoiceChip(
                    label: Text('مخصص', style: GoogleFonts.cairo()),
                    selected: _isCustomTarget,
                    onSelected: (_) => setState(() => _isCustomTarget = true),
                  ),
                ],
              ),
              if (_isCustomTarget) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customTargetController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(),
                  decoration: InputDecoration(
                    hintText: 'اكتب رقم الهدف',
                    hintStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const Divider(height: 28),
              Text(
                'تذكير الأذكار',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('تذكير أذكار الصباح', style: GoogleFonts.cairo()),
                value: _morningEnabled,
                onChanged: (value) => _onToggleMorning(value),
              ),
              if (_morningEnabled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('وقت تذكير الصباح', style: GoogleFonts.cairo()),
                  trailing: OutlinedButton(
                    onPressed: _pickMorningTime,
                    child: Text(_morningTime.format(context), style: GoogleFonts.cairo()),
                  ),
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('تذكير أذكار المساء', style: GoogleFonts.cairo()),
                value: _eveningEnabled,
                onChanged: (value) => _onToggleEvening(value),
              ),
              if (_eveningEnabled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('وقت تذكير المساء', style: GoogleFonts.cairo()),
                  trailing: OutlinedButton(
                    onPressed: _pickEveningTime,
                    child: Text(_eveningTime.format(context), style: GoogleFonts.cairo()),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: _darkGreen, foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('حفظ', style: GoogleFonts.cairo()),
        ),
      ],
    );
  }
}
