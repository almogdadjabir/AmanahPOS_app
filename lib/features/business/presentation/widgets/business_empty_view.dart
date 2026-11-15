import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/empty_view.dart';
import 'package:amana_pos/features/business/presentation/fancy_business_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class BusinessEmptyView extends StatelessWidget {
  const BusinessEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppEmptyView(
      icon: PhosphorIconsRegular.buildings,
      title: tr.noBusinessesYet,
      subtitle: tr.createFirstBusinessToGetStarted,
      ctaLabel: tr.addBusiness,
      ctaIcon: PhosphorIconsRegular.plusCircle,
      onCta: () => FancyBusinessBottomSheet.show(context),
    );
  }
}
