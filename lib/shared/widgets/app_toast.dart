import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

enum ToastType { success, info, warning, error }

class AppToast {
  AppToast._();

  static final Map<ToastType, Color> _backgroundColors = {
    ToastType.success: AppColors.success,
    ToastType.info: AppColors.blueLight,
    ToastType.warning: AppColors.warning,
    ToastType.error: AppColors.error,
  };

  static final Map<ToastType, IconData> _icons = {
    ToastType.success: Icons.check_circle_outline,
    ToastType.info: Icons.info_outline,
    ToastType.warning: Icons.warning_amber_rounded,
    ToastType.error: Icons.error_outline,
  };

  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    hide();

    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final safeTopMargin = topPadding > 0 ? topPadding + 16 : 16.0;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: safeTopMargin,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _backgroundColors[type],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icons[type], color: AppColors.white, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    _timer = Timer(duration, () {
      hide();
    });
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

