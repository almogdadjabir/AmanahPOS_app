import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/login_country.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

String countryName(AppLocalizations tr, LoginCountry c) => switch (c) {
  LoginCountry.sudan => tr.countrySudan,
  LoginCountry.uae => tr.countryUae,
};

/// Bottom sheet to pick the sign-in country. Resolves to the choice, or null.
Future<LoginCountry?> showCountrySheet(
  BuildContext context, {
  required LoginCountry selected,
}) {
  return showAppSheet<LoginCountry>(
    context,
    builder: (ctx) {
      final tr = ctx.tr;
      final colors = ctx.appColors;
      final text = Theme.of(ctx).textTheme;

      return AppSheet(
        title: tr.countryTitle,
        keyboardSafe: false,
        child: AppGroup(
          children: [
            for (final c in LoginCountry.values)
              Pressable(
                scale: 1,
                onTap: () => Navigator.of(ctx).pop(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s4,
                    vertical: AppDims.s4,
                  ),
                  child: Row(
                    children: [
                      Text(c.flag, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: AppDims.s3),
                      Expanded(
                        child: Text(
                          countryName(tr, c),
                          style: text.bodyLarge!.copyWith(
                            fontSize: 17,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        c.dialCode,
                        textDirection: TextDirection.ltr,
                        style: text.bodyLarge!.copyWith(
                          fontSize: 17,
                          color: colors.textHint,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: c == selected
                            ? Icon(
                                PhosphorIconsRegular.check,
                                size: 20,
                                color: colors.primary,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
