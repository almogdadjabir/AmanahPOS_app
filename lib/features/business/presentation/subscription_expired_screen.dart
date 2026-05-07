import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        pageBuilder: (_, __, ___) => const SubscriptionExpiredScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  static void close(BuildContext context) {
    if (!_isShowing) return;
    _isShowing = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  static void reset() => _isShowing = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopScope(
      // Prevent back button from dismissing the blocker.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDims.s6),
            child: Container(
              padding: const EdgeInsets.all(AppDims.s5),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppDims.rXl),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      size: 40,
                      color: Color(0xFFEF4444),
                    ),
                  ),

                  const SizedBox(height: AppDims.s4),

                  Text(
                    'Subscription Expired',
                    style: AppTextStyles.bs600(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppDims.s2),

                  Text(
                    'Your plan has expired. Please renew your subscription to continue using the app.',
                    style: AppTextStyles.bs200(context).copyWith(
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppDims.s5),

                  // Contact button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // TODO: open WhatsApp / email / URL for renewal
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDims.s3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Renew Subscription',
                        style: AppTextStyles.bs300(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDims.s2),

                  // Logout option
                  TextButton(
                    onPressed: () {
                      // Dispatch logout from AuthBloc
                      context.read<AuthBloc>().add(OnLogoutEvent());
                    },
                    child: Text(
                      'Sign out',
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}