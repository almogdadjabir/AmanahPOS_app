import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refund items are sent by item_id with a decimal quantity', () {
    final json = const RefundRequestDto(
      items: [
        RefundItemDto(itemId: 'line-1', quantity: 1),
        RefundItemDto(itemId: 'line-2', quantity: 1.5),
      ],
      notes: 'damaged',
    ).toJson();

    expect(json['notes'], 'damaged');
    final items = json['items'] as List;
    expect(items[0], {'item_id': 'line-1', 'quantity': 1.0});
    expect(items[1], {'item_id': 'line-2', 'quantity': 1.5});
    expect((items[0] as Map).containsKey('product_id'), isFalse);
  });

  test('an empty note is left out', () {
    final json = const RefundRequestDto(
      items: [RefundItemDto(itemId: 'a', quantity: 1)],
      notes: '',
    ).toJson();
    expect(json.containsKey('notes'), isFalse);
  });
}
