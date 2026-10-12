import 'package:flutter/material.dart';

/// The color of a kind of saved place, so a gym, a school and a home are told
/// apart at a glance. Each has an [foreground] for the icon / outline and a
/// pale (light theme) or deep (dark theme) [wash] behind it.
///
/// Light foregrounds are deep enough for 4.5:1 on their wash; dark ones are
/// the bright tone of the same hue.
enum PlaceAccent {
  home(
    lightForeground: Color(0xFF0B6B3A),
    lightWash: Color(0xFFDDEFE3),
    darkForeground: Color(0xFF5FCB8B),
    darkWash: Color(0xFF173A27),
  ),
  work(
    lightForeground: Color(0xFF1D4ED8),
    lightWash: Color(0xFFDBEAFE),
    darkForeground: Color(0xFF60A5FA),
    darkWash: Color(0xFF14284A),
  ),
  gym(
    lightForeground: Color(0xFFC2410C),
    lightWash: Color(0xFFFFEDD5),
    darkForeground: Color(0xFFFB923C),
    darkWash: Color(0xFF3A2210),
  ),
  school(
    lightForeground: Color(0xFF8A5A00),
    lightWash: Color(0xFFFEF3C7),
    darkForeground: Color(0xFFFBBF24),
    darkWash: Color(0xFF33270A),
  ),
  university(
    lightForeground: Color(0xFF6D28D9),
    lightWash: Color(0xFFEDE9FE),
    darkForeground: Color(0xFFA78BFA),
    darkWash: Color(0xFF25194A),
  ),
  family(
    lightForeground: Color(0xFFBE185D),
    lightWash: Color(0xFFFCE7F3),
    darkForeground: Color(0xFFF472B6),
    darkWash: Color(0xFF3A1530),
  ),

  /// A place the customer named themselves.
  custom(
    lightForeground: Color(0xFF0E7490),
    lightWash: Color(0xFFCFFAFE),
    darkForeground: Color(0xFF22D3EE),
    darkWash: Color(0xFF0C3440),
  );

  final Color lightForeground;
  final Color lightWash;
  final Color darkForeground;
  final Color darkWash;

  const PlaceAccent({
    required this.lightForeground,
    required this.lightWash,
    required this.darkForeground,
    required this.darkWash,
  });

  Color foreground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkForeground
          : lightForeground;

  Color wash(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkWash : lightWash;
}
