import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/splash/domain/blocs/splash_bloc.dart';
import 'package:amana_pos/features/splash/presentation/widgets/splash_progress.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The mark in exactly the place and size the native launch screen
/// draws it (Android windowBackground / splash, iOS LaunchScreen.storyboard),
/// so the OS splash hands off to this screen without a visible change, with a
/// thin progress bar below so the app never looks frozen. When
/// routing finishes, the mark glides to the next screen (shared Hero).
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
          case SplashStatus.pinLocked:
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteStrings.pinUnlockScreen,
              (route) => false,
            );
          case SplashStatus.unauthenticated:
          case SplashStatus.failure:
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(RouteStrings.login, (route) => false);
          case SplashStatus.initial:
          case SplashStatus.loading:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        body: Stack(
          children: [
            const Center(
              child: Hero(
                tag: amanaMarkHeroTag,
                child: AmanaPosLogoMark(size: 88),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 96,
              child: Center(
                child: SplashProgress(color: context.appColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
