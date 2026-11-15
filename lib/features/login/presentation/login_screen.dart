import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/login/presentation/login_code_screen.dart';
import 'package:amana_pos/features/login/presentation/widgets/login_form.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/utilities/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _codeOpen = false;
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status || prev.loginStatus != curr.loginStatus,
      listener: _handleLoginState,
      child: Scaffold(
        backgroundColor: context.appColors.background,
        resizeToAvoidBottomInset: true,
        body: const LoginForm(),
      ),
    );
  }

  void _handleLoginState(BuildContext context, LoginState state) {
    // The code step is its own route so it gets the platform push + swipe back.
    if (state.loginStatus == LoginStatus.otp && !_codeOpen) {
      _codeOpen = true;
      Utils.hideKeyboard(context);
      final bloc = context.read<LoginBloc>();
      Navigator.of(context)
          .push(
            CupertinoPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const LoginCodeScreen(),
              ),
            ),
          )
          .whenComplete(() => _codeOpen = false);
      return;
    }
    if (state.loginStatus == LoginStatus.form && _codeOpen && !_completing) {
      Navigator.of(context).maybePop();
      return;
    }

    if (state.status == PageStatus.failure &&
        state.responseError != null &&
        state.loginStatus != LoginStatus.otp) {
      Utils.hideKeyboard(context);
      GlobalSnackBar.show(
        message: state.responseError!,
        isError: true,
        isAutoDismiss: false,
      );
      return;
    }

    if (state.loginStatus == LoginStatus.competed) {
      _completing = true;
      final navigator = Navigator.of(context);
      final profile = state.loggedInUser;
      () async {
        final vault = getIt<PinVaultService>();
        final cache = getIt<CacheStorage>();
        final userId = profile?.id ?? '';
        final alreadyEnrolled =
            userId.isNotEmpty && await vault.isUserEnrolled(userId);
        if (!mounted) return;

        if (profile != null && !alreadyEnrolled) {
          final access = await cache.read(Constants.authToken) ?? '';
          final refresh = await cache.read(Constants.refreshToken) ?? '';
          final tenantId = await cache.read(Constants.xTenantID) ?? '';
          if (!mounted) return;
          navigator.pushNamedAndRemoveUntil(
            RouteStrings.pinSetupScreen,
            (route) => false,
            arguments: {
              'user': profile,
              'tokens': (access: access, refresh: refresh, tenantId: tenantId),
            },
          );
        } else {
          navigator.pushNamedAndRemoveUntil(
            RouteStrings.mainScreen,
            (route) => false,
          );
        }
      }();
      context.read<LoginBloc>().add(const OnResetEvent());
    }
  }
}
