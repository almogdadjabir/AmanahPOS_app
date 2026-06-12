import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessData tax fields', () {
    test('parses tax fields from json', () {
      final data = BusinessData.fromJson({
        'id': 'b1',
        'name': 'Main Shop',
        'tax_enabled': true,
        'tax_name': 'VAT',
        'tax_rate': '15.00',
        'tax_inclusive': false,
      });

      expect(data.taxEnabled, true);
      expect(data.taxName, 'VAT');
      expect(data.taxRate, '15.00');
      expect(data.taxInclusive, false);
    });

    test('missing tax fields parse to null (stale offline cache)', () {
      final data = BusinessData.fromJson({'id': 'b1', 'name': 'Old Shop'});

      expect(data.taxEnabled, isNull);
      expect(data.taxName, isNull);
      expect(data.taxRate, isNull);
      expect(data.taxInclusive, isNull);
    });

    test('toJson round-trips tax fields', () {
      final data = BusinessData.fromJson({
        'id': 'b1',
        'tax_enabled': true,
        'tax_name': 'GST',
        'tax_rate': '7.50',
        'tax_inclusive': true,
      });
      final json = data.toJson();

      expect(json['tax_enabled'], true);
      expect(json['tax_name'], 'GST');
      expect(json['tax_rate'], '7.50');
      expect(json['tax_inclusive'], true);
    });
  });

  group('BusinessData logo', () {
    // Regression: `logo` was code-generated as type `Null?`, so any business
    // with a non-null logo threw "type 'String' is not a subtype of type
    // 'Null'" during BusinessResponseDTO parsing → "something went wrong".
    test('parses a non-null logo string without throwing', () {
      final data = BusinessData.fromJson({
        'id': 'b1',
        'name': 'Bet Al Mandi',
        'logo': '/media/businesses/logos/512.png',
      });

      expect(data.logo, '/media/businesses/logos/512.png');
    });

    test('still accepts a null logo', () {
      final data = BusinessData.fromJson({'id': 'b1', 'logo': null});
      expect(data.logo, isNull);
    });

    test('BusinessResponseDTO parses a list item that has a logo', () {
      final dto = BusinessResponseDTO.fromJson({
        'success': true,
        'data': [
          {'id': 'b1', 'name': 'Bet Al Mandi', 'logo': '/media/x.png'},
        ],
      });

      expect(dto.data!.first.logo, '/media/x.png');
    });
  });
}
