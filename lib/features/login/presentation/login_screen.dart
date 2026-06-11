import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/login/presentation/widgets/login_form.dart';
import 'package:amana_pos/features/login/presentation/widgets/login_otp.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:amana_pos/widgets/grid_painter.dart';
import 'package:amana_pos/widgets/page_dots.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/utilities/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late PageController _pageController;

  final pages = [
    const LoginForm(),
    const LoginOtp(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status || prev.loginStatus != curr.loginStatus,
      listener: (context, state) => _handleLoginState(context, state),
      builder: (context, state) {
        // ── Desktop: web-style centered card layout ──────────────────────────────
        if (context.isDesktop) {
          return const _DesktopLoginBody();
        }

        // ── Mobile: existing Scaffold unchanged ──────────────────────────────────
        final isOtp = state.loginStatus == LoginStatus.otp;

        return Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: context.appColors.background,
            title: Stack(
              alignment: Alignment.center,
              children: [
                PageDots(currentPage: state.loginStatus.page),
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return RadialGradient(
                        center: const Alignment(0.45, -0.65),
                        radius: 0.95,
                        colors: [
                          context.appColors.textPrimary,
                          Colors.transparent,
                        ],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: CustomPaint(
                      painter: GridPainter(
                        color: context.appColors.primary.withValues(
                          alpha: 0.04,
                        ),
                        spacing: 24,
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    opacity: isOtp ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSlide(
                      offset: isOtp ? Offset.zero : const Offset(-0.3, 0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: IgnorePointer(
                        ignoring: !isOtp,
                        child: InkWell(
                          onTap: () => context
                              .read<LoginBloc>()
                              .add(const OnResetEvent(isPhoneChange: true)),
                          borderRadius: AppRadius.borderSm,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.appColors.surfaceSoft,
                              borderRadius: AppRadius.borderSm,
                              border:
                                  Border.all(color: context.appColors.border),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pages.length,
              itemBuilder: (context, index) => pages[index],
            ),
          ),
        );
      },
    );
  }

  void _handleLoginState(BuildContext context, LoginState state) {
    Utils.hideKeyboard(context);

    if (state.status == PageStatus.failure &&
        state.responseError != null &&
        state.loginStatus != LoginStatus.otp) {
      GlobalSnackBar.show(
        message: state.responseError!,
        isError: true,
        isAutoDismiss: false,
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (state.loginStatus == LoginStatus.competed) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteStrings.mainScreen,
          (route) => false,
        );
        context.read<LoginBloc>().add(const OnResetEvent());
        return;
      }

      // Desktop uses AnimatedSwitcher — no PageView to animate.
      if (!_pageController.hasClients) return;

      final targetPage = state.loginStatus.page;
      final currentPage = _pageController.page?.round() ?? 0;

      if (targetPage == currentPage) return;

      if ((targetPage - currentPage).abs() > 1) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        _pageController.jumpToPage(targetPage);
      } else {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
}

// ── Desktop layout ─────────────────────────────────────────────────────────────

class _DesktopLoginBody extends StatefulWidget {
  const _DesktopLoginBody();

  @override
  State<_DesktopLoginBody> createState() => _DesktopLoginBodyState();
}

class _DesktopLoginBodyState extends State<_DesktopLoginBody>
    with TickerProviderStateMixin {
  late final AnimationController _aura1 = AnimationController(
      vsync: this, duration: const Duration(seconds: 22))
    ..repeat(reverse: true);
  late final AnimationController _aura2 = AnimationController(
      vsync: this, duration: const Duration(seconds: 26))
    ..repeat(reverse: true);
  late final AnimationController _aura3 = AnimationController(
      vsync: this, duration: const Duration(seconds: 30))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _aura1.dispose();
    _aura2.dispose();
    _aura3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: _LoginAuraBackground(a1: _aura1, a2: _aura2, a3: _aura3),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 432),
                  child: Column(
                    children: [
                      const _LoginDesktopBrandBlock(),
                      const SizedBox(height: 28),
                      BlocBuilder<LoginBloc, LoginState>(
                        buildWhen: (prev, curr) =>
                            prev.loginStatus != curr.loginStatus,
                        builder: (context, state) {
                          return _LoginDesktopCard(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.03),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  )),
                                  child: child,
                                ),
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(state.loginStatus),
                                child: state.loginStatus == LoginStatus.otp
                                    ? const LoginOtp()
                                    : const LoginForm(),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const _LoginDesktopTrustRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated aura background ───────────────────────────────────────────────────

class _LoginAuraBackground extends StatelessWidget {
  const _LoginAuraBackground({
    required this.a1,
    required this.a2,
    required this.a3,
  });

  final AnimationController a1, a2, a3;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sz = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(
              color: colors.textPrimary.withValues(alpha: 0.04),
              spacing: 54,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: a1,
          builder: (_, _) => Positioned(
            top: -180 + a1.value * 30,
            left: -160 + a1.value * 40,
            child: _LoginAura(
              size: 560,
              color: colors.primary.withValues(alpha: 0.18),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: a2,
          builder: (_, _) => Positioned(
            bottom: -200 - a2.value * 24,
            right: -140 - a2.value * 36,
            child: _LoginAura(
              size: 520,
              color: colors.primary.withValues(alpha: 0.10),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: a3,
          builder: (_, _) => Positioned(
            top: sz.height * 0.40 + a3.value * 20,
            right: sz.width * 0.18 + a3.value * 15,
            child: _LoginAura(
              size: 360,
              color: colors.warning.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginAura extends StatelessWidget {
  const _LoginAura({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

// ── Desktop card ───────────────────────────────────────────────────────────────

class _LoginDesktopCard extends StatelessWidget {
  const _LoginDesktopCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 36),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.14),
            blurRadius: 50,
            spreadRadius: -28,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Brand block ────────────────────────────────────────────────────────────────

class _LoginDesktopBrandBlock extends StatelessWidget {
  const _LoginDesktopBrandBlock();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        const AmanaPosLogoMark(size: 56),
        const SizedBox(height: 16),
        Text(
          'AmanaPOS',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Point of Sale · Platform',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: colors.textHint,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ── Trust row ──────────────────────────────────────────────────────────────────

class _LoginDesktopTrustRow extends StatelessWidget {
  const _LoginDesktopTrustRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget dot() => Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: colors.textHint.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 13, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              'End-to-end encrypted',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: colors.textHint,
              ),
            ),
          ],
        ),
        dot(),
        Text(
          '2,400+ merchants',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            color: colors.textHint,
          ),
        ),
        dot(),
        Text(
          'Khartoum',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            color: colors.textHint,
          ),
        ),
      ],
    );
  }
}
