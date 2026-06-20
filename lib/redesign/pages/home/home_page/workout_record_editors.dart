part of '../home_page.dart';

DateTime? _parseClock(DateTime date, String raw) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(raw.trim());
  if (match == null) {
    return null;
  }
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) {
    return null;
  }
  return DateTime(date.year, date.month, date.day, hour, minute);
}

DateTime? _parseTimeParts(DateTime date, String rawHour, String rawMinute) {
  final hour = rawHour.trim();
  final minute = rawMinute.trim();
  if (hour.length != 2 || minute.length != 2) {
    return null;
  }
  return _parseClock(date, '$hour:$minute');
}

int? _parseDurationParts(String rawHours, String rawMinutes, String rawSeconds) {
  final hoursText = rawHours.trim();
  final minutesText = rawMinutes.trim();
  final secondsText = rawSeconds.trim();
  if (hoursText.length != 2 || minutesText.length != 2 || secondsText.length != 2) {
    return null;
  }
  final hours = int.tryParse(hoursText);
  final minutes = int.tryParse(minutesText);
  final seconds = int.tryParse(secondsText);
  if (hours == null || minutes == null || seconds == null) {
    return null;
  }
  if (hours > 23 || minutes > 59 || seconds > 59) {
    return null;
  }
  return hours * 3600 + minutes * 60 + seconds;
}

void _setDurationParts(
  int seconds,
  TextEditingController hourController,
  TextEditingController minuteController,
  TextEditingController secondController,
) {
  final safe = seconds.clamp(0, 23 * 3600 + 59 * 60 + 59);
  final duration = Duration(seconds: safe);
  hourController.text = duration.inHours.toString().padLeft(2, '0');
  minuteController.text = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  secondController.text = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
}

Widget _smallNumberField(
  BuildContext context,
  String label,
  TextEditingController controller, {
  bool decimal = false,
}) {
  final palette = context.yoursPalette;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          label,
          style: context
              .yoursText(YoursTextRole.body)
              .copyWith(fontSize: 12, color: palette.muted, fontWeight: FontWeight.w700),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: palette.panel,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textAlign: TextAlign.center,
          style: context
              .yoursText(YoursTextRole.body)
              .copyWith(color: palette.fg, fontWeight: FontWeight.w700),
          cursorColor: palette.accent,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Config Sheet
// ═══════════════════════════════════════════════════════════════════════════════
