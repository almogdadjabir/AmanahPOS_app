import 'package:amana_pos/l10n/app_localizations.dart';

extension AppLocalizationsProductX on AppLocalizations {
  String expiredBatchLabel(int count) {
    if (count <= 0) return '';
    if (count == 1) return expiredBatchOne;
    return expiredBatchMany(count);
  }

  String expiringSoonBatchLabel(int count) {
    if (count <= 0) return '';
    return expiringSoonBatchMany(count);
  }

  String productExpirySummary({
    required int expiredCount,
    required int expiringSoonCount,
  }) {
    final parts = <String>[];

    final expiredText = expiredBatchLabel(expiredCount);
    if (expiredText.isNotEmpty) parts.add(expiredText);

    final expiringSoonText = expiringSoonBatchLabel(expiringSoonCount);
    if (expiringSoonText.isNotEmpty) parts.add(expiringSoonText);

    return parts.join(' · ');
  }

  String dayCountLabel(int count) {
    if (count <= 0) return '';
    if (count == 1) return oneDay;
    return manyDays(count);
  }
}