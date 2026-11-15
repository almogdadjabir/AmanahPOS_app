import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/customers/presentation/customer_form_screen.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_format.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_row.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerData customer;

  const CustomerDetailScreen({super.key, required this.customer});

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}
    if (context.mounted) {
      GlobalSnackBar.show(
        message: context.tr.somethingWentWrong,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final canManage = !context.select<AuthBloc, bool>(
      (b) => b.state.permissions.isCashier,
    );

    // Live copy: an edit or status change shows up here without reopening.
    final c = context.select<CustomersBloc, CustomerData>((bloc) {
      for (final item in bloc.state.customers) {
        if (item.id == customer.id) return item;
      }
      return customer;
    });

    final active = c.isActive != false;
    final phone = c.phone?.trim() ?? '';
    final email = c.email?.trim() ?? '';
    final address = c.address?.trim() ?? '';
    final notes = c.notes?.trim() ?? '';
    final spent = double.tryParse(c.totalPurchases ?? '') ?? 0;
    final since = DateTime.tryParse(c.createdAt ?? '');
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(
              backLabel: tr.cuTitle,
              editLabel: tr.cuEdit,
              onEdit: () => openCustomerForm(context, customer: c),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4,
                  0,
                  AppDims.s4,
                  MediaQuery.viewPaddingOf(context).bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
                    Center(
                      child: CustomerAvatar(
                        customer: c,
                        size: 84,
                        inactive: !active,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      c.name?.trim() ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        height: 31 / 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        phone,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (!active) ...[
                      const SizedBox(height: 14),
                      _Banner(text: tr.cuInactiveBanner),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionTile(
                            icon: PhosphorIconsRegular.phone,
                            label: tr.cuCall,
                            onTap: phone.isEmpty
                                ? null
                                : () => _launch(
                                    context,
                                    Uri(scheme: 'tel', path: phone),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionTile(
                            icon: PhosphorIconsRegular.whatsappLogo,
                            label: tr.cuWhatsApp,
                            onTap: phoneDigits(phone).isEmpty
                                ? null
                                : () => _launch(
                                    context,
                                    Uri.parse(
                                      'https://wa.me/${phoneDigits(phone)}',
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionTile(
                            icon: PhosphorIconsRegular.envelopeSimple,
                            label: tr.cuEmailAction,
                            onTap: email.isEmpty
                                ? null
                                : () => _launch(
                                    context,
                                    Uri(scheme: 'mailto', path: email),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value: saleNumber(spent),
                            unit: tr.shUnit,
                            label: tr.cuTotalPurchases,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            value: '${c.loyaltyPoints ?? 0}',
                            label: tr.cuLoyalty,
                          ),
                        ),
                      ],
                    ),
                    if (phone.isNotEmpty ||
                        email.isNotEmpty ||
                        address.isNotEmpty) ...[
                      _Section(tr.cuContact),
                      _Card(
                        children: [
                          if (phone.isNotEmpty)
                            _KvRow(label: tr.cuPhone, value: phone, ltr: true),
                          if (email.isNotEmpty)
                            _KvRow(label: tr.cuEmail, value: email, ltr: true),
                          if (address.isNotEmpty)
                            _KvRow(
                              label: tr.cuAddress,
                              value: address,
                              stacked: true,
                            ),
                        ],
                      ),
                    ],
                    if (notes.isNotEmpty) ...[
                      _Section(tr.cuNotes),
                      _Card(
                        children: [
                          _KvRow(value: notes, stacked: true, strong: true),
                        ],
                      ),
                    ],
                    if (since != null) ...[
                      const _Section(''),
                      _Card(
                        children: [
                          _KvRow(
                            label: tr.cuSince,
                            value: DateFormat.yMMM(
                              locale,
                            ).format(since.toLocal()),
                          ),
                        ],
                      ),
                    ],
                    if (canManage) ...[
                      const SizedBox(height: 22),
                      _Card(
                        children: [
                          Pressable(
                            scale: 1,
                            onTap: () => active
                                ? confirmDeactivateCustomer(context, c)
                                : reactivateCustomer(context, c),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 50),
                              child: Center(
                                child: Text(
                                  active ? tr.cuDeactivate : tr.cuReactivate,
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                    color: active
                                        ? colors.danger
                                        : colors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final String backLabel;
  final String editLabel;
  final VoidCallback onEdit;

  const _NavBar({
    required this.backLabel,
    required this.editLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      backLabel,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Pressable(
              onTap: onEdit,
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: Text(
                      editLabel,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  const _Banner({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              PhosphorIconsRegular.prohibit,
              size: 20,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 20 / 15,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = onTap == null ? colors.disabled : colors.primary;

    return Pressable(
      onTap: onTap,
      haptic: true,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String? unit;
  final String label;

  const _StatTile({required this.value, this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: value,
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: colors.textHint,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 13, height: 1.3, color: colors.textHint),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox(height: 29);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 7),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
          color: context.appColors.textHint,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4,
                  color: colors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline row (label at the start, value at the end) or stacked row (label
/// above a wrapping value).
class _KvRow extends StatelessWidget {
  final String? label;
  final String value;
  final bool ltr;
  final bool stacked;
  final bool strong;

  const _KvRow({
    this.label,
    required this.value,
    this.ltr = false,
    this.stacked = false,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (stacked) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.3,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  height: 21 / 15,
                  color: strong ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              label ?? '',
              style: TextStyle(
                fontSize: 17,
                height: 1.3,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                textDirection: ltr ? TextDirection.ltr : null,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  color: colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
