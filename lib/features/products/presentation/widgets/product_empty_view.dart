import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductEmptyView extends StatelessWidget {
  final String title;
  final String message;
  final bool hasCategories;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionText;

  const ProductEmptyView({
    super.key,
    required this.title,
    required this.message,
    this.hasCategories = true,
    this.onPrimaryAction,
    this.primaryActionText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppDims.s5),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.border.withOpacity(0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmptyIcon(hasCategories: hasCategories),
              const SizedBox(height: AppDims.s5),

              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),

              const SizedBox(height: AppDims.s2),

              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs400(context).copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: colors.textSecondary,
                ),
              ),

              const SizedBox(height: AppDims.s5),

              _SetupSteps(hasCategories: hasCategories),

              if (onPrimaryAction != null && primaryActionText != null) ...[
                const SizedBox(height: AppDims.s5),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: Icon(
                      hasCategories
                          ? Icons.add_shopping_cart_rounded
                          : Icons.category_rounded,
                      size: 20,
                    ),
                    label: Text(
                      primaryActionText!,
                      style: AppTextStyles.bs300(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyIcon extends StatelessWidget {
  final bool hasCategories;

  const _EmptyIcon({required this.hasCategories});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            hasCategories
                ? Icons.inventory_2_outlined
                : Icons.layers_rounded,
            size: 42,
            color: colors.primary,
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: hasCategories ? colors.primary : Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 3),
              ),
              child: Icon(
                hasCategories ? Icons.add_rounded : Icons.priority_high_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupSteps extends StatelessWidget {
  final bool hasCategories;

  const _SetupSteps({required this.hasCategories});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepTile(
          number: 1,
          title: 'Create a category',
          subtitle: 'Example: Drinks, Food, Groceries, Electronics',
          isDone: hasCategories,
          isActive: !hasCategories,
        ),
        const SizedBox(height: AppDims.s3),
        _StepTile(
          number: 2,
          title: 'Add your products',
          subtitle: 'Products need at least one category before selling.',
          isDone: false,
          isActive: hasCategories,
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  const _StepTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final iconColor = isDone || isActive
        ? colors.primary
        : colors.textSecondary.withOpacity(0.45);

    final bgColor = isDone || isActive
        ? colors.primaryContainer
        : colors.background;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? colors.primary.withOpacity(0.35)
              : colors.border.withOpacity(0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDone ? colors.primary : colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withOpacity(0.45),
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              )
                  : Text(
                '$number',
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: iconColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bs300(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}