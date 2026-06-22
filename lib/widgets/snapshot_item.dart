import 'package:flutter/material.dart';

class SnapshotItem extends StatelessWidget {
  final String label;
  final String value;
  final Widget logo;
  final Color? valueColor;

  const SnapshotItem({
    super.key,
    required this.label,
    required this.value,
    required this.logo,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: 4),
        Text(label),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: valueColor ?? Colors.black87)),
      ],
    );
  }
}
