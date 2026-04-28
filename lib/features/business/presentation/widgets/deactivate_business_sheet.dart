import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showDeactivateSheet(BuildContext context, BusinessData business) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<BusinessBloc>(),
      child: _DeactivateSheet(business: business),
    ),
  );
}

class _DeactivateSheet extends StatelessWidget {
  final BusinessData business;
  const _DeactivateSheet({required this.business});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusinessBloc, BusinessState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == BusinessSubmitStatus.success) {
          Navigator.of(context)
            ..pop()
            ..pop();
          GlobalSnackBar.show(
              message: 'Business deactivated',
              isWarning: true,
          );
        }

        if (state.submitStatus == BusinessSubmitStatus.failure) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
              message: state.submitError ?? 'Something went wrong',
              isError: true,
              isAutoDismiss: false
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: context.appColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppDims.s4),

            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: context.appColors.dangerContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.block_rounded,
                  size: 30, color: context.appColors.danger),
            ),
            const SizedBox(height: AppDims.s3),

            Text(
              'Deactivate Business?',
              style: AppTextStyles.bs600(context).copyWith(
              fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
              child: Text(
                '"${business.name}" will be deactivated. '
                    'All associated shops will stop operating. '
                    'You can reactivate it later.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bs400(context).copyWith(
                fontWeight: FontWeight.w600,
                  color: context.appColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppDims.s5),

            BlocBuilder<BusinessBloc, BusinessState>(
              buildWhen: (prev, curr) =>
              prev.submitStatus != curr.submitStatus,
              builder: (context, state) {
                final isLoading =
                    state.submitStatus == BusinessSubmitStatus.loading;

                return Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDims.s3),
                          side: BorderSide(color: context.appColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(AppDims.rMd),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.bs400(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDims.s3),

                    // Confirm
                    Expanded(
                      child: FilledButton(
                        onPressed: isLoading
                            ? null
                            : () => context.read<BusinessBloc>().add(
                          OnDeactivateBusiness(
                              businessId: business.id!),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          disabledBackgroundColor:
                          context.appColors.border,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDims.s3),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(AppDims.rMd),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Deactivate',
                          style: AppTextStyles.bs400(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}