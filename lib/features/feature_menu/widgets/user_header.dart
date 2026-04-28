import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserHeader extends StatelessWidget {
  final VoidCallback onClose;
  const UserHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      color: context.appColors.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(),
          const SizedBox(width: AppDims.s3),
          Expanded(child: _UserInfo()),
          const SizedBox(width: AppDims.s3),
          _CloseButton(onClose: onClose),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, User?>(
      selector: (state) => state.profile,
      builder: (context, profile) {
        return Container(
          width: 56, height: 56,
          decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            profile?.fullName?.initials ?? '?',
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D6E6E),
            ),
          ),
        );
      },
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, User?>(
      selector: (state) => state.profile,
      builder: (context, profile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.fullName ?? '',
              style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w800, color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
             Text(
              '${profile?.role} · Khartoum',
              style: AppTextStyles.bs200(context).copyWith(
                fontWeight: FontWeight.w600, color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onClose;
  const _CloseButton({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDims.rMd),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}