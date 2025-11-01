import 'package:flutter/material.dart';

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFED5A79), brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    cardTheme: const CardTheme(margin: EdgeInsets.all(8)),
    appBarTheme: AppBarTheme(backgroundColor: scheme.surface, foregroundColor: scheme.onSurface),
  );
}

extension AppType on BuildContext {
  TextStyle get titleSection => Theme.of(this).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800);
}

class GmBadge extends StatelessWidget {
  final String text; final IconData? icon;
  const GmBadge(this.text, {super.key, this.icon});
  @override Widget build(BuildContext context){
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withOpacity(.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: c.primary), const SizedBox(width: 4)],
        Text(text, style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class GmProgressRing extends StatelessWidget {
  final double value; final String? label;
  const GmProgressRing({super.key, required this.value, this.label});
  @override Widget build(BuildContext context){
    return Stack(alignment: Alignment.center, children:[
      SizedBox(width:72, height:72, child: CircularProgressIndicator(value: value.clamp(0,1), strokeWidth:8)),
      Text(label ?? '${(value*100).round()}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}
