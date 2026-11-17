import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

const kUserRoles = ['cashier', 'manager'];

extension UserDataView on UserData {
  bool get isManager => role == 'manager';
  bool get isActiveUser => isActive != false;

  /// Never verified and never signed in: the invite is still pending.
  bool get isInvited => isVerified != true && lastLoginAt == null;

  String get displayName {
    final n = fullName?.trim();
    return n != null && n.isNotEmpty ? n : (phone ?? '');
  }

  DateTime? get lastLogin => _parse(lastLoginAt);
  DateTime? get joinedAt => _parse(createdAt);
}

DateTime? _parse(String? v) =>
    v == null || v.isEmpty ? null : DateTime.tryParse(v)?.toLocal();

/// "OS" / Arabic first letter.
String userInitials(BuildContext context, String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  if (Localizations.localeOf(context).languageCode == 'ar') {
    return words.first.characters.first;
  }
  return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
}

/// "+249 91 700 1122" for Sudan numbers, the raw value otherwise.
String formatUserPhone(String? phone) {
  final p = phone?.trim() ?? '';
  final m = RegExp(r'^\+249(\d{2})(\d{3})(\d{4})$').firstMatch(p);
  if (m == null) return p;
  return '+249 ${m[1]} ${m[2]} ${m[3]}';
}

/// Today / Yesterday / N days ago / date.
String userLastSignInShort(BuildContext context, DateTime date) {
  final tr = context.tr;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return tr.tmToday;
  if (diff == 1) return tr.tmYesterday;
  if (diff < 7) return tr.tmDaysAgo(diff);
  return DateFormat.yMMMd(locale).format(date);
}

/// "Today, 08:42" / "12 Mar 2026, 08:42".
String userLastSignInLong(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  final time = DateFormat('HH:mm').format(date);
  final dayText = diff <= 0
      ? context.tr.tmToday
      : diff == 1
      ? context.tr.tmYesterday
      : DateFormat.yMMMd(locale).format(date);
  return '$dayText, $time';
}

String userJoined(BuildContext context, DateTime date) => DateFormat.yMMM(
  Localizations.localeOf(context).toLanguageTag(),
).format(date);

String userRoleLabel(BuildContext context, String? role) =>
    role == 'manager' ? context.tr.tmRoleManager : context.tr.tmRoleCashier;

String userRoleDesc(BuildContext context, String role) => role == 'manager'
    ? context.tr.tmRoleManagerDesc
    : context.tr.tmRoleCashierDesc;

/// Active shops of the current business (id set, not deactivated).
List<ShopData> activeShops(BuildContext context) {
  final shops = context.read<AuthBloc>().state.defaultBusiness?.shops;
  if (shops == null) return const [];
  return [
    for (final s in shops)
      if ((s.id?.trim().isNotEmpty ?? false) && (s.isActive ?? true)) s,
  ];
}

/// Branch pickers show only when there is a real choice.
bool hasMultipleShops(BuildContext context) =>
    context.select<AuthBloc, bool>((b) {
      final shops = b.state.defaultBusiness?.shops;
      if (shops == null) return false;
      return shops
              .where(
                (s) =>
                    (s.id?.trim().isNotEmpty ?? false) && (s.isActive ?? true),
              )
              .length >
          1;
    });

String? shopName(List<ShopData> shops, String? id) {
  if (id == null) return null;
  for (final s in shops) {
    if (s.id == id) return s.name?.trim();
  }
  return null;
}

/// The owner row and the signed-in user are managed elsewhere: the BE
/// refuses their edits, so no edit entry points are offered.
bool canEditTeamMember(BuildContext context, UserData user) {
  // The profile may not be hydrated yet: the signed-in scope names the user
  // (`userId|tenantId`) without it. Nobody known -> offer nothing.
  final me =
      context.read<AuthBloc>().state.profile?.id ??
      SyncScope.current?.split('|').first;
  return me != null && user.role != 'owner' && user.id != me;
}

/// "Now: Manager" / "Your change: Cashier": what a refused change was about.
String userChangeSummary(
  BuildContext context,
  Map<String, dynamic> payload,
  List<ShopData> shops,
) {
  final parts = <String>[];
  final tr = context.tr;
  if (payload['role'] is String) {
    parts.add(
      '${tr.tmRole}: ${userRoleLabel(context, payload['role'] as String)}',
    );
  }
  final shop = payload['default_shop_id'];
  if (shop is String) {
    parts.add('${tr.tmBranch}: ${shopName(shops, shop) ?? shop}');
  }
  if (payload['full_name'] is String) parts.add(payload['full_name'] as String);
  if (payload['is_active'] is bool) {
    parts.add(
      payload['is_active'] == true ? tr.userChangeReactivate : tr.tmInactive,
    );
  }
  return parts.join(', ');
}
