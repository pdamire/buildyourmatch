import 'package:flutter/material.dart';

class GmProgressRing extends StatelessWidget {
  final double value; // value between 0.0 and 1.0
  final double size;
  final double stroke;

  const GmProgressRing({
    super.key,
    required this.value,
    this.size = 50,
    this.stroke = 6,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: clampedValue,
            strokeWidth: stroke,
          ),
          Text(
            '${(clampedValue * 100).round()}%',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
