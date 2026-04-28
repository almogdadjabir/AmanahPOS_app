import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';

class FeatureMenu extends StatefulWidget {
  final bool open;
  final VoidCallback onDismiss;
  final VoidCallback? onSignOut;

  const FeatureMenu({
    super.key,
    required this.open,
    required this.onDismiss,
    this.onSignOut,
  });

  @override
  State<FeatureMenu> createState() => _FeatureMenuState();
}

class _FeatureMenuState extends State<FeatureMenu> {
  // Explicit controller fixes "PrimaryScrollController attached to more than
  // one ScrollPosition" when Scrollbar.thumbVisibility is true.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static final List<_Section> _sections = [
    _Section('Operations', [
      _Item('pos',    'POS / Sales', 'New sale & checkout',
          Icons.point_of_sale_rounded,      Color(0xFF0D9488), active: true),
      _Item('orders', 'Orders',      'History & refunds',
          Icons.receipt_long_rounded,       Color(0xFF0EA5E9)),
      _Item('cust',   'Customers',   'CRM & loyalty',
          Icons.people_alt_rounded,         Color(0xFFEC4899)),
    ]),
    _Section('Inventory', [
      _Item('prod',  'Products',        'Catalog & variants',
          Icons.local_offer_rounded,        Color(0xFF0EA5E9)),
      _Item('cat',   'Categories',      'Menu structure',
          Icons.layers_rounded,             Color(0xFF8B5CF6)),
      _Item('stock', 'Stock Control',   'Levels & transfers',
          Icons.inventory_2_rounded,        Color(0xFFEC4899)),
      _Item('po',    'Purchase Orders', 'Suppliers & deliveries',
          Icons.local_shipping_rounded,     Color(0xFF0891B2)),
    ]),
    _Section('Insights', [
      _Item('rep',   'Reports',          'Sales & tax reports',
          Icons.show_chart_rounded,         Color(0xFF22C55E)),
      _Item('shift', 'Shifts & Drawers', 'Open / close cashflow',
          Icons.schedule_rounded,           Color(0xFFEA580C)),
    ]),
    _Section('Admin', [
      _Item('team',   'User Management',    'Staff, roles, PINs',
          Icons.badge_rounded,              Color(0xFFDB2777)),
      _Item('branch', 'Branches & Devices', 'Locations, printers',
          Icons.store_mall_directory_rounded, Color(0xFF475569)),
      _Item('set',    'Settings',           'Tax, currency, payments',
          Icons.settings_rounded,           Color(0xFF475569)),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return IgnorePointer(
      ignoring: !widget.open,
      child: Stack(
        children: [
          // ── Backdrop ────────────────────────────────────────────────
          AnimatedOpacity(
            duration: AppDims.fast,
            opacity: widget.open ? 1 : 0,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          ),

          // ── Sheet ────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRect(
              child: AnimatedSlide(
                offset: widget.open ? Offset.zero : const Offset(0, -1),
                duration: AppDims.medium,
                curve: Curves.easeOutCubic,
                child: Material(
                  color: context.appColors.surface,
                  elevation: 0,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppDims.rXl),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    bottom: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxH),
                      child: Column(
                        // DO NOT use mainAxisSize.min here — the Flexible child
                        // needs the Column to fill the constrained height so it
                        // can allocate remaining space to the scroll area.
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Teal user header (fixed) ──────────────
                          _UserHeader(onClose: widget.onDismiss),

                          // ── Scrollable body (fills remaining space) ──
                          Flexible(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              radius: const Radius.circular(999),
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                // primary: false prevents this view from
                                // attaching to the PrimaryScrollController,
                                // which fixes the "more than one position" error.
                                primary: false,
                                padding: const EdgeInsets.fromLTRB(
                                  AppDims.s4, AppDims.s4,
                                  AppDims.s4, AppDims.s4,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    for (var i = 0;
                                    i < _sections.length;
                                    i++) ...[
                                      _SectionLabel(
                                          label: _sections[i].title),
                                      const SizedBox(height: AppDims.s2),
                                      _SectionGrid(
                                        items: _sections[i].items,
                                        onPick: (_) => widget.onDismiss(),
                                      ),
                                      if (i < _sections.length - 1)
                                        const SizedBox(height: AppDims.s5),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Sticky footer (fixed, no SafeArea) ──────
                          _Footer(onSignOut: widget.onSignOut),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Teal user header ─────────────────────────────────────────────────────────

class _UserHeader extends StatefulWidget {
  final VoidCallback onClose;
  const _UserHeader({required this.onClose});

  @override
  State<_UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<_UserHeader> {
  late final Timer _timer;
  Duration _elapsed = const Duration(hours: 3, minutes: 42, seconds: 11);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _shiftTime {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    const headerBg = Color(0xFF0D6E6E);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s4, AppDims.s4, AppDims.s4),
      color: headerBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'SA',
              style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 18,
                fontWeight: FontWeight.w800, color: Color(0xFF0D6E6E),
              ),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sara Al-Mutairi',
                  style: TextStyle(
                    fontFamily: 'NunitoSans', fontSize: 16,
                    fontWeight: FontWeight.w800, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('Cashier · Khartoum',
                  style: TextStyle(
                    fontFamily: 'NunitoSans', fontSize: 12,
                    fontWeight: FontWeight.w600, color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80), shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Shift open · $_shiftTime',
                        style: const TextStyle(
                          fontFamily: 'NunitoSans', fontSize: 11,
                          fontWeight: FontWeight.w700, color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s3),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'NunitoSans', fontSize: 10.5, fontWeight: FontWeight.w800,
        color: context.appColors.textHint, letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Section grid ─────────────────────────────────────────────────────────────

class _SectionGrid extends StatelessWidget {
  final List<_Item> items;
  final ValueChanged<_Item> onPick;
  const _SectionGrid({required this.items, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppDims.s3,
      crossAxisSpacing: AppDims.s3,
      childAspectRatio: 2.15,
      children: items
          .map((it) => _FeatureTile(item: it, onTap: () => onPick(it)))
          .toList(),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _Item item;
  final VoidCallback onTap;
  const _FeatureTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = item.active;
    return Material(
      color: active
          ? context.appColors.primaryContainer
          : context.appColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s3, vertical: AppDims.s2),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Icon(item.icon, size: 22, color: item.color),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'NunitoSans', fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? context.appColors.primary
                                  : context.appColors.textPrimary,
                            ),
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.appColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NOW',
                              style: TextStyle(
                                fontFamily: 'NunitoSans', fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NunitoSans', fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sticky footer ────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final VoidCallback? onSignOut;
  const _Footer({this.onSignOut});

  @override
  Widget build(BuildContext context) {
    // No SafeArea here — the menu is capped at 75 % height and has bottom
    // radius, so there is no home-indicator overlap to worry about.
    // Removing SafeArea eliminates the white gap that was appearing below
    // the footer inside the rounded sheet.
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
            onPressed: (){
              getIt<AuthBloc>().add(const OnLogoutEvent());

            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              backgroundColor: context.appColors.background,
              side: BorderSide(color: context.appColors.border,),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDims.s3, vertical: AppDims.s2),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rSm),
              ),
              textStyle: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: Icon(Icons.logout_rounded, size: 16, color: context.appColors.danger,),
            label: Text(
                'Sign out',
              style: TextStyle(
                color: context.appColors.danger,
              )
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _Section {
  final String title;
  final List<_Item> items;
  const _Section(this.title, this.items);
}

class _Item {
  final String id;
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final bool active;
  const _Item(
      this.id, this.name, this.desc, this.icon, this.color, {
        this.active = false,
      });
}