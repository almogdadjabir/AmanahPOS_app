import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FooterStatus extends StatelessWidget {
  const FooterStatus({super.key,
    required this.state,
  });

  final OfflineStatusState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final canRetry = state.hasFailure &&
        state.connectionStatus == OfflineConnectionStatus.online;

    return Column(
      children: [
        if (canRetry)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                context.read<OfflineStatusBloc>().add(
                  const OnOfflineStatusRefreshRequested(),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                textStyle: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s3,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.connectionStatus == OfflineConnectionStatus.online
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  size: 17,
                  color: state.connectionStatus == OfflineConnectionStatus.online
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: AppDims.s2),
                Flexible(
                  child: Text(
                    '${state.connectionLabel} · ${state.statusLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs200(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppDims.s3),
        Text(
          'This setup is required only once. After that, AmanaPOS can keep working during poor internet.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}