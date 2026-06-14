import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/settings/presentation/widgets/owner_header.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_animation_picker.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_theme_picker.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

/// Left column of the desktop settings layout: identity card, workspace
/// summary, sync status and the sign-out action — gives the page an
/// "account panel" anchor instead of one long scrolling list.
class DesktopSettingsSidebar extends StatelessWidget {
  final User profile;
  final String? businessName;
  final VoidCallback onSignOut;

  const DesktopSettingsSidebar({
    super.key,
    required this.profile,
    required this.businessName,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;

    final name = profile.fullName?.trim().isNotEmpty == true
        ? profile.fullName!.trim()
        : 'User';
    final initials = initialsFor(name);
    final roleData = roleDataFor(profile.role);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDims.s5),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rXl),
            border: Border.all(
              color: colors.primary.withValues(alpha: isDark ? 0.26 : 0.16),
              width: 1.1,
            ),
            gradient: RadialGradient(
              center: const Alignment(0.0, -1.1),
              radius: 1.6,
              colors: [
                colors.primary.withValues(alpha: isDark ? 0.20 : 0.08),
                colors.surface.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.7],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.38),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.bs500(context).copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s4),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile.phone?.trim().isNotEmpty == true
                    ? profile.phone!.trim()
                    : 'AmanaPOS account',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppDims.s3),
              RolePill(label: roleData.label, color: roleData.color),
            ],
          ),
        ),
        const SizedBox(height: AppDims.s3),
        if (businessName != null && businessName!.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppDims.s4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(color: colors.border.withValues(alpha: 0.75)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    SolarIconsOutline.shop,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WORKSPACE',
                        style: AppTextStyles.sm100(context).copyWith(
                          color: colors.textHint,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        businessName!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppDims.s5),
        Text(
          tr.settingsSectionAppearance.toUpperCase(),
          style: AppTextStyles.sm100(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppDims.s2),
        BlocSelector<ThemeBloc, ThemeState, ScreenMode?>(
          selector: (state) => state.mode,
          builder: (context, mode) {
            return SettingsThemePicker(
              selectedMode: mode ?? ScreenMode.device,
              onModeSelected: (selectedMode) {
                context
                    .read<ThemeBloc>()
                    .add(OnThemeChangeEvent(mode: selectedMode));
              },
            );
          },
        ),
        const SizedBox(height: AppDims.s3),
        Text(
          tr.settingsAnimations,
          style: AppTextStyles.sm100(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppDims.s2),
        BlocSelector<ThemeBloc, ThemeState, AnimationPreference>(
          selector: (state) => state.animationPreference,
          builder: (context, pref) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsAnimationPicker(
                  selected: pref,
                  onSelected: (p) {
                    if (p == pref) return;
                    context
                        .read<ThemeBloc>()
                        .add(OnAnimationsPreferenceChanged(p));
                  },
                ),
                if (pref == AnimationPreference.auto) ...[
                  const SizedBox(height: AppDims.s1),
                  Text(
                    tr.settingsAnimationsAutoSubtitle,
                    style: AppTextStyles.bs100(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppDims.s3),
        const _LanguageDropdown(),
        const SizedBox(height: AppDims.s5),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: Icon(Icons.logout_rounded, size: 18, color: colors.danger),
          label: Text(
            tr.settingsSignOut,
            style: AppTextStyles.bs200(context).copyWith(
              fontWeight: FontWeight.w800,
              color: colors.danger,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
            side: BorderSide(color: colors.danger.withValues(alpha: 0.35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageDropdown extends StatefulWidget {
  const _LanguageDropdown();

  @override
  State<_LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<_LanguageDropdown>
    with SingleTickerProviderStateMixin {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _isOpen = false;
  double _triggerWidth = 220;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _isOpen = true);
    _overlayController.show();
    _animController.forward(from: 0);
  }

  void _close() {
    _animController.reverse().then((_) {
      if (mounted) {
        _overlayController.hide();
        setState(() => _isOpen = false);
      }
    });
  }

  void _toggle() => _isOpen ? _close() : _open();

  @override
  Widget build(BuildContext context) {
    final localeBloc = context.read<LocaleBloc>();

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (_) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              followerAnchor: Alignment.topLeft,
              targetAnchor: Alignment.bottomLeft,
              offset: const Offset(0, 6),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _LanguageDropdownMenu(
                    localeBloc: localeBloc,
                    onClose: _close,
                    width: _triggerWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _triggerWidth = constraints.maxWidth;
            return BlocBuilder<LocaleBloc, LocaleState>(
              builder: (context, _) {
                final colors = context.appColors;
                final tr = context.tr;
                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDims.rLg),
                  child: InkWell(
                    onTap: _toggle,
                    borderRadius: BorderRadius.circular(AppDims.rLg),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(AppDims.s3),
                      decoration: BoxDecoration(
                        color: _isOpen
                            ? colors.primary.withValues(alpha: 0.06)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(AppDims.rLg),
                        border: Border.all(
                          color: _isOpen
                              ? colors.primary.withValues(alpha: 0.30)
                              : colors.border.withValues(alpha: 0.75),
                          width: _isOpen ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(
                                alpha: _isOpen ? 0.18 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(AppDims.rMd),
                            ),
                            child: Icon(
                              SolarIconsOutline.global,
                              color: colors.primary,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: AppDims.s3),
                          Expanded(
                            child: Text(
                              tr.currentLanguageName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs200(context).copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: _isOpen ? colors.primary : colors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LanguageDropdownMenu extends StatelessWidget {
  final LocaleBloc localeBloc;
  final VoidCallback onClose;
  final double width;

  const _LanguageDropdownMenu({
    required this.localeBloc,
    required this.onClose,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return BlocBuilder<LocaleBloc, LocaleState>(
      bloc: localeBloc,
      builder: (context, state) {
        final current = state.locale.languageCode;
        return Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(color: colors.border.withValues(alpha: 0.75)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DropdownItem(
                  badge: 'A',
                  title: tr.languageEnglish,
                  subtitle: tr.languageEnglishNative,
                  isSelected: current == 'en',
                  onTap: () {
                    localeBloc.add(const OnLocaleChanged(languageCode: 'en'));
                    onClose();
                  },
                ),
                const SizedBox(height: 3),
                _DropdownItem(
                  badge: 'ع',
                  title: tr.languageArabic,
                  subtitle: tr.languageArabicNative,
                  isSelected: current == 'ar',
                  onTap: () {
                    localeBloc.add(const OnLocaleChanged(languageCode: 'ar'));
                    onClose();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: isSelected ? 0.16 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: AppTextStyles.bs300(context).copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.sm200(context).copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
