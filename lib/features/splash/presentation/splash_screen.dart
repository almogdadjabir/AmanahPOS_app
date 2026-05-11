import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/splash/domain/blocs/splash_bloc.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SplashBloc>().add(const SplashStarted());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<SplashBloc, SplashState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case SplashStatus.authenticated:
            getIt<AuthBloc>().add(OnLoadProfileEvent());
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteStrings.mainScreen,
              (route) => false,
            );
            break;
          case SplashStatus.unauthenticated:
          case SplashStatus.failure:
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteStrings.login,
              (route) => false,
            );
            break;
          case SplashStatus.initial:
          case SplashStatus.loading:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [

            const _SplashGlow(),


            SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  const _SplashLogoSection(),

                  const SizedBox(height: 40),

                  Text(
                    'أمانة',
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.bs800(context).copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1,
                    ),
                  )
                      .animate(delay: 280.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 10),

                  Text(
                    'POINT  OF  SALE',
                    style: AppTextStyles.sm200(context).copyWith(
                      color: colors.textHint,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4.5,
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 400.ms),

                  const Spacer(),

                  const _SplashProgressBar(),

                  const SizedBox(height: 12),

                  Text(
                    'v1.0.0',
                    style: AppTextStyles.sm200(context).copyWith(
                      color: colors.textHint.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ).animate(delay: 700.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SplashGlow extends StatelessWidget {
  const _SplashGlow();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors.primaryContainer.withValues(alpha: 0.38),
              colors.primaryContainer.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 900.ms, curve: Curves.easeOut);
  }
}


class _SplashLogoSection extends StatelessWidget {
  const _SplashLogoSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
              )
              .fade(
                begin: 0.25,
                end: 1.0,
                duration: 2800.ms,
                curve: Curves.easeInOut,
              ),

          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.13),
                width: 1,
              ),
            ),
          )
              .animate(
                delay: 460.ms,
                onPlay: (c) => c.repeat(reverse: true),
              )
              .fade(
                begin: 0.20,
                end: 1.0,
                duration: 2200.ms,
                curve: Curves.easeInOut,
              ),

          AmanaPosLogoMark(size: 96)
              .animate()
              .scale(
                begin: const Offset(0.72, 0.72),
                end: const Offset(1.0, 1.0),
                duration: 560.ms,
                delay: 60.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(
                duration: 380.ms,
                delay: 60.ms,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}


class _SplashProgressBar extends StatefulWidget {
  const _SplashProgressBar();

  @override
  State<_SplashProgressBar> createState() => _SplashProgressBarState();
}

class _SplashProgressBarState extends State<_SplashProgressBar> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Delay so the bar starts after the logo enters.
    Future.delayed(const Duration(milliseconds: 680), () {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final total = constraints.maxWidth;
          return Stack(
            children: [
              // Track
              Container(
                width: total,
                height: 1,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              // Beam — sweeps the full track width
              AnimatedContainer(
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOut,
                width: _started ? total : 0,
                height: 1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.55),
                      colors.primary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ).animate(delay: 600.ms).fadeIn(duration: 300.ms);
  }
}
