import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/add_business_sheet.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class BusinessEmptyView extends StatelessWidget {
  const BusinessEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: SolarIconsOutline.buildings_2,
      title: tr.noBusinessesYet,
      subtitle: tr.createFirstBusinessToGetStarted,
      ctaLabel: tr.addBusiness,
      ctaIcon: SolarIconsOutline.addCircle,
      onCta: () => showAddBusinessSheet(context),
    );
  }
}
