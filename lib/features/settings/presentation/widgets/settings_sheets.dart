import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _OptionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool last;

  const _OptionRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        Pressable(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          scale: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 18 / 13,
                                color: colors.textHint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(
                      PhosphorIconsRegular.check,
                      size: 22,
                      color: colors.primary,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!last)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: AppDims.s4,
            color: colors.border,
          ),
      ],
    );
  }
}

Widget _card(BuildContext context, List<Widget> rows) {
  final colors = context.appColors;
  return DecoratedBox(
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: AppDims.borderLg,
      border: Border.all(color: colors.border),
    ),
    child: ClipRRect(
      borderRadius: AppDims.borderLg,
      child: Column(children: rows),
    ),
  );
}

void openLanguageSheet(BuildContext context) {
  final bloc = context.read<LocaleBloc>();
  showAppSheet<void>(
    context,
    builder: (_) =>
        BlocProvider.value(value: bloc, child: const _LanguageSheet()),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return AppSheet(
      title: tr.mrLanguage,
      trailingAction: AppSheetAction(
        label: tr.done,
        emphasized: true,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, state) {
          final code = state.locale.languageCode;

          void pick(String c) {
            if (c == code) return;
            context.read<LocaleBloc>().add(OnLocaleChanged(languageCode: c));
          }

          return _card(context, [
            _OptionRow(
              title: tr.languageEnglishNative,
              selected: code == 'en',
              onTap: () => pick('en'),
            ),
            _OptionRow(
              title: tr.languageArabicNative,
              selected: code == 'ar',
              last: true,
              onTap: () => pick('ar'),
            ),
          ]);
        },
      ),
    );
  }
}

void openAnimationSheet(BuildContext context) {
  final bloc = context.read<ThemeBloc>();
  showAppSheet<void>(
    context,
    builder: (_) =>
        BlocProvider.value(value: bloc, child: const _AnimationSheet()),
  );
}

String animationLabel(BuildContext context, AnimationPreference p) {
  final tr = context.tr;
  return switch (p) {
    AnimationPreference.auto => tr.mrAnimAuto,
    AnimationPreference.alwaysOn => tr.mrAnimOn,
    AnimationPreference.alwaysOff => tr.mrAnimOff,
  };
}

class _AnimationSheet extends StatelessWidget {
  const _AnimationSheet();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return AppSheet(
      title: tr.mrAnimations,
      trailingAction: AppSheetAction(
        label: tr.done,
        emphasized: true,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: BlocSelector<ThemeBloc, ThemeState, AnimationPreference>(
        selector: (s) => s.animationPreference,
        builder: (context, pref) {
          void pick(AnimationPreference p) {
            if (p == pref) return;
            context.read<ThemeBloc>().add(OnAnimationsPreferenceChanged(p));
          }

          return _card(context, [
            _OptionRow(
              title: tr.mrAnimAuto,
              subtitle: tr.mrAnimAutoHint,
              selected: pref == AnimationPreference.auto,
              onTap: () => pick(AnimationPreference.auto),
            ),
            _OptionRow(
              title: tr.mrAnimOn,
              selected: pref == AnimationPreference.alwaysOn,
              onTap: () => pick(AnimationPreference.alwaysOn),
            ),
            _OptionRow(
              title: tr.mrAnimOff,
              selected: pref == AnimationPreference.alwaysOff,
              last: true,
              onTap: () => pick(AnimationPreference.alwaysOff),
            ),
          ]);
        },
      ),
    );
  }
}
