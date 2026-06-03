import 'dart:ui';

import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/features/notification/presentation/notifications_dropdown.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  void _onTap() {
    if (context.isDesktop) {
      _overlayController.toggle();
    } else {
      Navigator.pushNamed(context, RouteStrings.notificationsScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (_) => NotificationsDropdown(
          link: _link,
          onClose: _overlayController.hide,
          notificationBloc: context.read<NotificationBloc>(),
        ),
        child: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 46,
            height: 46,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.70),
                      width: 1.1,
                    ),
                  ),
                  child: Center(
                    child: BlocSelector<NotificationBloc, NotificationState, int?>(
                      selector: (s) => s.unreadCount,
                      builder: (context, count) {
                        final icon = Icon(
                          SolarIconsOutline.bell,
                          size: 20,
                          color: colors.textSecondary,
                        );
                        if (count == null || count == 0) return icon;
                        return Badge.count(
                          count: count,
                          backgroundColor: colors.danger,
                          textColor: Colors.white,
                          child: icon,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
