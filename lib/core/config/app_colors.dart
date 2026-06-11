import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF0EA5A4);
  static const primaryDark = Color(0xFF087F7E);
  static const primarySoft = Color(0xFFE0F7F6);
  static const secondary = Color(0xFF2563EB);
  static const secondarySoft = Color(0xFFEFF6FF);
  static const background = Color(0xFFF6FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFFE4E6);
  static const violet = Color(0xFF7C3AED);
  static const violetSoft = Color(0xFFF3E8FF);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color backgroundOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF0B1120) : background;
  }

  static Color surfaceOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF111827) : surface;
  }

  static Color surfaceMutedOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF1E293B) : surfaceMuted;
  }

  static Color borderOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF334155) : border;
  }

  static Color textPrimaryOf(BuildContext context) {
    return isDark(context) ? const Color(0xFFF8FAFC) : textPrimary;
  }

  static Color textMutedOf(BuildContext context) {
    return isDark(context) ? const Color(0xFFCBD5E1) : textMuted;
  }

  static Color primarySoftOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF123F44) : primarySoft;
  }

  static Color secondarySoftOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF172554) : secondarySoft;
  }

  static Color successSoftOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF052E16) : successSoft;
  }

  static Color warningSoftOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF451A03) : warningSoft;
  }

  static Color dangerSoftOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF450A0A) : dangerSoft;
  }

  static Color violetSoftOf(BuildContext context) {
    return isDark(context) ? const Color(0xFF2E1065) : violetSoft;
  }
}
