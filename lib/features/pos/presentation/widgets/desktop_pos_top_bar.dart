import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/widgets/app_progress_line.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

/// Desktop POS top bar — spans the full width above the 3-column workstation.
///
/// Left: cash icon + "Cashier" + dynamic shop name.
/// Middle: horizontal shop-switcher pills (multi-shop owners only; hidden for cashiers).
/// Right: animated refresh button.
/// Bottom edge: [AppProgressLine].
class DesktopPosTopBar extends StatefulWidget {
  const DesktopPosTopBar({
    super.key,
    required this.onRefresh,
    required this.onShopSelected,
  });

  final Future<void> Function() onRefresh;
  final void Function(String shopId, String shopName) onShopSelected;

  @override
  State<DesktopPosTopBar> createState() => _DesktopPosTopBarState();
}

class _DesktopPosTopBarState extends State<DesktopPosTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _busy = false;

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        final next = DateTime.now();
        if (next.minute != _now.minute) setState(() => _now = next);
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _spinCtrl.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  Future<void> _handleRefresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    _spinCtrl.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinCtrl
          ..stop()
          ..value = 0;
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDims.s5,
            ),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    SolarIconsOutline.cartLarge_4,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDims.s3),

                // Title + shop subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cashier',
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    BlocBuilder<PosBloc, PosState>(
                      buildWhen: (prev, curr) =>
                          prev.selectedShopName != curr.selectedShopName,
                      builder: (context, posState) {
                        final shop = posState.selectedShopName;
                        return Text(
                          (shop != null && shop.isNotEmpty)
                              ? shop
                              : 'Point of sale',
                          style: AppTextStyles.sm300(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: AppDims.s5),

                // Shop switcher (hidden for cashiers and single-shop owners)
                Expanded(
                  child: _ShopSwitcherRow(
                    onShopSelected: widget.onShopSelected,
                  ),
                ),
                const SizedBox(width: AppDims.s4),

                // Live clock
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_now),
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(_now),
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textHint,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppDims.s4),

                // Refresh button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                  child: InkWell(
                    onTap: _handleRefresh,
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                        color: colors.surfaceSoft.withValues(alpha: 0.65),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.75),
                        ),
                      ),
                      child: RotationTransition(
                        turns: _spinCtrl,
                        child: Icon(
                          SolarIconsOutline.refresh,
                          size: 19,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const AppProgressLine(),
      ],
    );
  }
}

// ── Shop switcher ─────────────────────────────────────────────────────────────

class _ShopSwitcherRow extends StatelessWidget {
  const _ShopSwitcherRow({required this.onShopSelected});

  final void Function(String shopId, String shopName) onShopSelected;

  @override
  Widget build(BuildContext context) {
    final permissions = context.read<AuthBloc>().state.permissions;
    if (permissions.isCashier) return const SizedBox.shrink();

    return BlocBuilder<BusinessBloc, BusinessState>(
      buildWhen: (prev, curr) => prev.businessList != curr.businessList,
      builder: (context, bizState) {
        final shops = bizState.businessList
                ?.expand((b) => b.shops ?? [])
                .where((s) => s.id != null && (s.isActive ?? true))
                .toList() ??
            [];
        if (shops.length < 2) return const SizedBox.shrink();

        return BlocBuilder<PosBloc, PosState>(
          buildWhen: (prev, curr) =>
              prev.selectedShopId != curr.selectedShopId,
          builder: (context, posState) {
            final colors = context.appColors;

            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: shops.map((shop) {
                    final isSelected = shop.id == posState.selectedShopId;

                    return Padding(
                      padding:
                          const EdgeInsetsDirectional.only(end: AppDims.s2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : colors.surfaceSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                isSelected ? colors.primary : colors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            onTap: isSelected
                                ? null
                                : () => onShopSelected(
                                      shop.id!,
                                      shop.name ?? 'Shop',
                                    ),
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDims.s3,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 13,
                                    color: isSelected
                                        ? Colors.white
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    shop.name ?? 'Shop',
                                    style: AppTextStyles.bs100(context)
                                        .copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : colors.textSecondary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
