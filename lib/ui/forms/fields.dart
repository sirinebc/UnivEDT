import 'package:flutter/material.dart';
import '../../utils.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color primaryColor;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final double? height;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.primaryColor,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1, 
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          Flexible( 
            child: TextField(
              cursorColor: primaryColor,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hintText,
                filled:true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildTimePicker({
  required BuildContext context,
  required String label,
  required TimeOfDay time,
  required Function(TimeOfDay) onChanged,
}) {
  return InkWell(
    onTap: () async {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: time,
        initialEntryMode: TimePickerEntryMode.inputOnly,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.grey[200],
              hourMinuteTextColor: Colors.black,
              dayPeriodTextColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        ),
      );
      if (pickedTime != null) onChanged(pickedTime);
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(time.format(context), style: const TextStyle(fontSize: 14)),
        ],
      ),
    ),
  );
}
