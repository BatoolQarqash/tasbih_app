import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/counter_provider.dart';
import '../providers/reminder_provider.dart';

const _darkGreen = Color(0xFF1B4332);

// Dialog الإعدادات: اختيار هدف التسبيح + تفعيل التذكير اليومي ووقته
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

  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  late String _reminderMessage;

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

    final reminder = ref.read(reminderProvider);
    _reminderEnabled = reminder.enabled;
    _reminderTime = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    _reminderMessage = reminder.message;
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
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

    final granted = await ref.read(reminderProvider.notifier).setReminder(
          enabled: _reminderEnabled,
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
          message: _reminderMessage,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (_reminderEnabled && !granted) {
      setState(() => _reminderEnabled = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('الإشعارات غير مفعّلة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text(
            'تم رفض صلاحية الإشعارات. لتفعيل التذكير اليومي، يرجى تفعيل الإشعارات لهذا التطبيق يدوياً من إعدادات الجهاز.',
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
              'تذكير يومي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('تفعيل التذكير اليومي', style: GoogleFonts.cairo()),
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
            ),
            if (_reminderEnabled) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('وقت التذكير', style: GoogleFonts.cairo()),
                trailing: OutlinedButton(
                  onPressed: _pickTime,
                  child: Text(_reminderTime.format(context), style: GoogleFonts.cairo()),
                ),
              ),
              const SizedBox(height: 8),
              Text('نص التذكير', style: GoogleFonts.cairo(fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _reminderMessage,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: reminderMessages
                    .map((msg) => DropdownMenuItem(value: msg, child: Text(msg, style: GoogleFonts.cairo())))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _reminderMessage = value);
                },
              ),
            ],
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
