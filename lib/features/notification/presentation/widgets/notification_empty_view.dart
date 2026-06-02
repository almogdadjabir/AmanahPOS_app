import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class NotificationEmptyView extends StatelessWidget {
  const NotificationEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: SolarIconsOutline.bell,
      title: tr.noNotificationsYet,
      subtitle: tr.allCaughtUpNewNotificationsWillAppearHere,
    );
  }
}
