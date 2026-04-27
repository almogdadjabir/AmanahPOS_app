import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/login/presentation/widgets/login_form.dart';
import 'package:amana_pos/features/login/presentation/widgets/login_otp.dart';
import 'package:amana_pos/features/login/presentation/widgets/page_dots.dart';
import 'package:amana_pos/theme/app_spacing.dart';
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
          RouteStrings.dashboard,
              (route) => false,
        );
        context.read<LoginBloc>().add(const OnResetEvent());
        return;
      }

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