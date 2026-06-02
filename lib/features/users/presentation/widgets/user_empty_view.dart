import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/add_user_sheet.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class UserEmptyView extends StatelessWidget {
  const UserEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: SolarIconsOutline.usersGroupRounded,
      title: tr.noCashiersYet,
      subtitle: tr.noCashiersYetDescription,
      ctaLabel: tr.addCashier,
      ctaIcon: SolarIconsOutline.userPlus,
      onCta: () => showAddUserSheet(context),
    );
  }
}
