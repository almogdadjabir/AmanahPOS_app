import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSwipeAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AppSwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// iOS style swipe-to-reveal actions on a row. Drag toward the start side to
/// reveal up to two actions at the end edge; releases snap open or closed.
/// Works in LTR and RTL. Tap on the row while open closes it.
class AppSwipeActions extends StatefulWidget {
  final Widget child;
  final List<AppSwipeAction> actions;

  const AppSwipeActions({
    super.key,
    required this.child,
    required this.actions,
  });

  @override
  State<AppSwipeActions> createState() => _AppSwipeActionsState();
}

class _AppSwipeActionsState extends State<AppSwipeActions>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 84;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDims.sheet,
  );

  double get _full => _actionWidth * widget.actions.length;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d, bool rtl) {
    final delta = (rtl ? d.delta.dx : -d.delta.dx) / _full;
    final before = _ctrl.value;
    _ctrl.value = (_ctrl.value + delta).clamp(0.0, 1.0);
    if (before < 0.5 && _ctrl.value >= 0.5) HapticFeedback.selectionClick();
  }

  void _end(DragEndDetails d, bool rtl) {
    final v = (rtl ? d.velocity.pixelsPerSecond.dx : -d.velocity.pixelsPerSecond.dx);
    final open = v.abs() > 400 ? v > 0 : _ctrl.value > 0.5;
    _settle(open);
  }

  void _settle(bool open) {
    final target = open ? 1.0 : 0.0;
    if (!Motion.on) {
      _ctrl.value = target;
      return;
    }
    _ctrl.animateTo(target, curve: AppDims.sheetCurve);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return ClipRect(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => _drag(d, rtl),
        onHorizontalDragEnd: (d) => _end(d, rtl),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(
                  width: _full,
                  child: Row(
                    children: [
                      for (final a in widget.actions)
                        SizedBox(
                          width: _actionWidth,
                          child: _ActionButton(
                            action: a,
                            onTap: () {
                              _settle(false);
                              a.onTap();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final dx = _ctrl.value * _full * (rtl ? 1 : -1);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: AbsorbPointerWhenOpen(
                controller: _ctrl,
                onTapClosed: () => _settle(false),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// While the row is open, a tap anywhere on it closes the row instead of
/// activating it.
class AbsorbPointerWhenOpen extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onTapClosed;
  final Widget child;

  const AbsorbPointerWhenOpen({
    super.key,
    required this.controller,
    required this.onTapClosed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final open = controller.value > 0.02;
        if (!open) return child;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTapClosed,
          child: AbsorbPointer(child: child),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AppSwipeAction action;
  final VoidCallback onTap;

  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: action.color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 22, color: Colors.white),
            const SizedBox(height: 3),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
