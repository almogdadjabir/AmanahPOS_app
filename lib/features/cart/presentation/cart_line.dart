import 'package:amana_pos/core/permissions/discount_access.dart';
import 'package:amana_pos/features/approval/presentation/owner_approval_sheet.dart';
import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/cart/presentation/discount_sheet.dart';
import 'package:amana_pos/features/pos/domain/cart_discount.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/cart/presentation/qty_stepper.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:amana_pos/widgets/app_amount.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartLine extends StatelessWidget {
  const CartLine({super.key, required this.item});

  final PosCartItem item;

  void _remove(BuildContext context, String productId, String name) {
    final bloc = context.read<PosBloc>();
    final overlay = Overlay.of(context, rootOverlay: true);
    final tr = context.tr;
    final product = item.product;
    final quantity = item.quantity;

    bloc.add(PosRemoveItem(productId));

    _UndoToast.show(
      overlay,
      message: tr.itemRemovedUndo(name),
      actionLabel: tr.undo,
      onUndo: () {
        bloc.add(PosAddProduct(product, ignoreStockLimit: true));
        for (var i = 1; i < quantity; i++) {
          bloc.add(PosIncrementItem(productId, ignoreStockLimit: true));
        }
      },
    );
  }

  DiscountAccess _access(BuildContext context, BusinessFeatures? f) =>
      discountAccess(
        context.read<AuthBloc>().state.permissions,
        f ?? getIt<BusinessFeaturesService>().current,
      );

  /// A cashier in "owner PIN" mode needs the owner first.
  Future<bool> _allowed(BuildContext context) async {
    if (_access(context, null) != DiscountAccess.approval) return true;
    return ensureOwnerApproval(context, what: context.tr.oaWhatDiscount);
  }

  Future<void> _openDiscount(BuildContext context, String name) async {
    final tr = context.tr;
    final bloc = context.read<PosBloc>();
    final id = item.product.id;
    if (id == null) return;
    if (!await _allowed(context) || !context.mounted) return;
    final r = await showDiscountSheet(
      context,
      title: tr.dcLineTitle,
      subtitle: tr.dcLineSub(name, '${item.quantity}', money(item.price)),
      baseCents: item.grossCents,
      initial: item.discount,
    );
    if (r == null) return;
    bloc.add(PosLineDiscountSet(id, r.discount));
  }

  @override
  Widget build(BuildContext context) {
    final features = getIt<BusinessFeaturesService>();
    return StreamBuilder<BusinessFeatures>(
      stream: features.changes,
      initialData: features.current,
      builder: (context, snap) => _build(
        context,
        (snap.data?.lineDiscount ?? true) &&
            _access(context, snap.data) != DiscountAccess.none,
      ),
    );
  }

  Widget _build(BuildContext context, bool canDiscount) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final productId = item.product.id;
    final imageUrl = item.product.thumbnailUrl ?? item.product.image;
    final productName = _safeText(item.product.name, context.tr.product);

    final line = Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppDims.s3),
      child: Row(
        children: [
          _ProductThumb(
            imageUrl: imageUrl,
            name: productName,
            isCustom: item.isCustom,
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: productName.contentDirection,
                  style: text.bodyLarge!.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          context.tr.eachPrice(money(item.price)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall!
                              .copyWith(color: colors.textHint)
                              .tabular,
                        ),
                      ),
                    ),
                    if (canDiscount && productId != null) ...[
                      const SizedBox(width: AppDims.s2),
                      Pressable(
                        onTap: () => _openDiscount(context, productName),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            context.tr.dcDiscount,
                            style: text.bodySmall!.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s3),
          QtyStepper(
            qty: item.quantity,
            onMinus: productId == null
                ? null
                : () =>
                      context.read<PosBloc>().add(PosDecrementItem(productId)),
            onPlus: productId == null
                ? null
                : () {
                    final isRestaurant = context
                        .read<AuthBloc>()
                        .state
                        .permissions
                        .isRestaurant;

                    context.read<PosBloc>().add(
                      PosIncrementItem(
                        productId,
                        ignoreStockLimit: isRestaurant,
                      ),
                    );
                  },
          ),
          const SizedBox(width: AppDims.s3),
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.discountCents > BigInt.zero) ...[
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      money(item.lineGross),
                      style: text.bodySmall!
                          .copyWith(
                            color: colors.textHint,
                            decoration: TextDecoration.lineThrough,
                          )
                          .tabular,
                    ),
                  ),
                ],
                AppAmount(
                  value: money(item.lineTotal),
                  style: text.bodyLarge!.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.discountCents > BigInt.zero)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      item.discount!.kind == DiscountKind.percent
                          ? '−${item.discount!.value}%'
                          : '−${money(item.lineDiscount)}',
                      style: text.labelSmall!.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return RepaintBoundary(
      child: productId == null
          ? line
          : Dismissible(
              key: ValueKey('cart-line-$productId'),
              direction: DismissDirection.endToStart,
              background: const _DeleteBackground(),
              onDismissed: (_) => _remove(context, productId, productName),
              child: ColoredBox(color: colors.surface, child: line),
            ),
    );
  }
}

class _UndoToast extends StatefulWidget {
  const _UndoToast({
    required this.message,
    required this.actionLabel,
    required this.onUndo,
    required this.onClosed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onUndo;
  final VoidCallback onClosed;

  static OverlayEntry? _current;

  static void show(
    OverlayState overlay, {
    required String message,
    required String actionLabel,
    required VoidCallback onUndo,
  }) {
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _UndoToast(
        message: message,
        actionLabel: actionLabel,
        onUndo: onUndo,
        onClosed: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  @override
  State<_UndoToast> createState() => _UndoToastState();
}

class _UndoToastState extends State<_UndoToast> {
  Timer? _timer;
  bool _visible = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _timer = Timer(const Duration(seconds: 4), _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    setState(() => _visible = false);
    await Future<void>.delayed(Motion.duration(AppDims.medium));
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final bottom = MediaQuery.viewPaddingOf(context).bottom + 96;

    return PositionedDirectional(
      start: AppDims.s4,
      end: AppDims.s4,
      bottom: bottom,
      child: AnimatedSlide(
        duration: Motion.duration(AppDims.medium),
        curve: AppDims.soft,
        offset: _visible ? Offset.zero : const Offset(0, 0.4),
        child: AnimatedOpacity(
          duration: Motion.duration(AppDims.medium),
          opacity: _visible ? 1 : 0,
          child: Material(
            color: colors.textPrimary,
            borderRadius: AppDims.borderMd,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppDims.s4,
                  end: AppDims.s1,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium!.copyWith(
                          color: colors.background,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Pressable(
                      onTap: () {
                        widget.onUndo();
                        _close();
                      },
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppDims.s3,
                          vertical: AppDims.s3,
                        ),
                        child: Text(
                          widget.actionLabel,
                          style: text.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final onError = Theme.of(context).colorScheme.onError;

    return ColoredBox(
      color: colors.danger,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: AppDims.s5),
          child: Text(
            context.tr.delete,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: onError,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({
    required this.imageUrl,
    required this.name,
    this.isCustom = false,
  });

  final String? imageUrl;
  final String name;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasImage = imageUrl?.trim().isNotEmpty == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDims.rSm + 2),
      child: SizedBox(
        width: 40,
        height: 40,
        child: hasImage
            ? OfflineCachedImage(imageUrl: imageUrl, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: BoxDecoration(color: colors.surfaceSoft),
                child: Center(
                  child: isCustom
                      ? Icon(
                          PhosphorIconsRegular.calculator,
                          size: 20,
                          color: colors.primary,
                        )
                      : Text(
                          AppFormat.initials(name, max: 1),
                          style: Theme.of(context).textTheme.titleSmall!
                              .copyWith(color: colors.textHint),
                        ),
                ),
              ),
      ),
    );
  }
}

String _safeText(String? value, String fallback) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}
