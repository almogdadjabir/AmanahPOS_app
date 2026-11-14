import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  void _onTap(BuildContext context) {
    Navigator.pushNamed(context, RouteStrings.notificationsScreen);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Pressable(
      onTap: () => _onTap(context),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: BlocSelector<NotificationBloc, NotificationState, int?>(
            selector: (s) => s.unreadCount,
            builder: (context, count) {
              final icon = Icon(
                PhosphorIconsRegular.bell,
                size: 19,
                color: colors.textPrimary,
              );
              if (count == null || count == 0) return icon;
              return Badge.count(
                count: count,
                backgroundColor: colors.danger,
                textColor: colors.onPrimary,
                child: icon,
              );
            },
          ),
        ),
      ),
    );
  }
}
