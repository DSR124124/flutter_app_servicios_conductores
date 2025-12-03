import 'package:flutter/material.dart';

/// Paleta de colores NETTALCO Design System
class AppColors {
  // ====== BRANDING COLORS ======

  // Navy Colors (Primary)
  static const Color navyDark = Color(0xFF1C224D);
  static const Color navyLighter = Color(0xFF2A3066);
  static const Color navyDarker = Color(0xFF141A3D);

  // Blue Colors (Secondary/Highlight)
  static const Color blueLight = Color(0xFF4A7AFF);
  static const Color blueLighter = Color(0xFF6B8FFF);
  static const Color blueDarker = Color(0xFF2954FF);
  static const Color lightBlue = Color(0xB2B7CAFF);

  // Mint Colors (Accent)
  static const Color mintLight = Color(0xFFA2F0A1);
  static const Color mintLighter = Color(0xFFB8F5B7);
  static const Color mintDarker = Color(0xFF7ED47D);

  // Teal Colors
  static const Color tealDark = Color(0xFF176973);

  // ====== NEUTRAL COLORS ======

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFE6E6E6);
  static const Color grayMedium = Color(0xFF7A7A7A);
  static const Color grayDark = Color(0xFF4A5568);
  static const Color grayLight = Color(0xFFF7FAFC);
  static const Color grayLighter = Color(0xFFEDF2F7);

  // ====== STATE COLORS ======

  static const Color success = Color(0xFFA2F0A1);
  static const Color info = Color(0xFF4A7AFF);
  static const Color warning = Color(0xFFFFA726);
  static const Color danger = Color(0xFFEF5350);

  // ====== LAYOUT COLORS ======

  static const Color layoutHeaderBg = Color(0xFF1C224D);
  static const Color layoutSidebarBg = Color(0xFFF5F8FC);
  static const Color layoutFooterBg = Color(0xFF151515);
  static const Color layoutMainBg = Color(0xFFFFFFFF);

  // ====== TEXT COLORS ======

  static const Color textoContent = Color(0xFF000000);
  static const Color textoHeader = Color(0xFFFFFFFF);
  static const Color textoFooter = Color(0xFFFFFFFF);
  static const Color textoSidebar = Color(0xFFFFFFFF);
  static const Color primaryContent = Color(0xFFFFFFFF);

  // ====== ALIASES ======

  static const Color primary = navyDark;
  static const Color primaryDark = navyDarker;
  static const Color primaryLight = navyLighter;

  static const Color secondary = blueLight;
  static const Color secondaryDark = blueDarker;
  static const Color secondaryLight = blueLighter;

  static const Color background = grayLight;
  static const Color surface = white;

  static const Color textPrimary = textoContent;
  static const Color textSecondary = grayMedium;
  static const Color textHint = grayLighter;

  static const Color error = danger;
  static const Color border = lightGray;
  static const Color disabled = grayMedium;
}

