part of '../home_page.dart';

class _SplitDurationFields extends StatelessWidget {
  final String keyPrefix;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final TextEditingController secondController;
  final VoidCallback onChanged;

  const _SplitDurationFields({
    required this.keyPrefix,
    required this.hourController,
    required this.minuteController,
    required this.secondController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return YoursTimeValue(
      keyPrefix: keyPrefix,
      hourController: hourController,
      minuteController: minuteController,
      secondController: secondController,
      onChanged: onChanged,
    );
  }
}
