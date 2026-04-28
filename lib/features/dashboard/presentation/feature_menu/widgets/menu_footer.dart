import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';

class MenuFooter extends StatelessWidget {
  final VoidCallback? onSignOut;
  const MenuFooter({super.key, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4, vertical: AppDims.s3),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        border: Border(top: BorderSide(color: context.appColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'v2.4.1 · synced',
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.appColors.textHint,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => getIt<AuthBloc>().add(const OnLogoutEvent()),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              backgroundColor: context.appColors.background,
              side: BorderSide(color: context.appColors.border),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDims.s3, vertical: AppDims.s2),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rSm),
              ),
              textStyle: const TextStyle(
                fontFamily: 'NunitoSans', fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: Icon(Icons.logout_rounded, size: 16,
                color: context.appColors.danger),
            label: Text(
              'Sign out',
              style: TextStyle(color: context.appColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}