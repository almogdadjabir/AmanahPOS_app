import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/splash/domain/blocs/splash_bloc.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
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
      listenWhen: (previous, current) => previous.status != current.status,
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
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Spacer(),

                _SplashLogo()
                    .animate()
                    .fadeIn(
                  duration: 500.ms,
                  curve: Curves.easeOut,
                )
                    .scale(
                  begin: const Offset(0.86, 0.86),
                  end: const Offset(1, 1),
                  duration: 650.ms,
                  curve: Curves.easeOutBack,
                ),
                const SizedBox(height: 22),
                Text(
                  'Amana POS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 450.ms)
                    .slideY(
                  begin: 0.25,
                  end: 0,
                  duration: 450.ms,
                  curve: Curves.easeOut,
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart point of sale',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 450.ms)
                    .slideY(
                  begin: 0.25,
                  end: 0,
                  duration: 450.ms,
                  curve: Curves.easeOut,
                ),
                Spacer(),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.primary,
                  ),
                ).animate(delay: 650.ms).fadeIn(duration: 350.ms),
                const SizedBox(height: 30),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 44,
            color: colors.onPrimary,
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.onPrimary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}