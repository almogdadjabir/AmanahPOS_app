import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/pos/data/model/requests/create_sale_request_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CreateSaleRequestDto.toJson never contains tax fields', () {
    const dto = CreateSaleRequestDto(
      clientSaleId: 'c1',
      shop: 's1',
      customer: null,
      paymentMethod: 'cash',
      discountAmount: '0',
      items: [CreateSaleItemDto(productId: 'p1', quantity: '1', unitPrice: '50.00')],
    );

    final json = dto.toJson();
    expect(json.containsKey('tax_amount'), false);
    expect(json.containsKey('tax_rate'), false);
    expect(json.containsKey('tax_inclusive'), false);
  });

  test('OfflineSaleDto.toSyncJson never contains tax fields', () {
    final dto = OfflineSaleDto(
      clientSaleId: 'c1',
      shopId: 's1',
      customerId: null,
      paymentMethod: 'cash',
      discountAmount: '0',
      taxAmount: '13.50', // local preview — stored, never sent
      subtotal: '90.00',
      total: '103.50',
      createdAt: DateTime.utc(2026, 6, 12),
      items: [
        OfflineSaleItemDto(
          productId: 'p1',
          productName: 'Item',
          quantity: 1,
          unitPrice: '90.00',
          lineTotal: '90.00',
          productSnapshot: ProductData.fromJson(const {'id': 'p1'}),
        ),
      ],
    );

    final json = dto.toSyncJson();
    expect(json.containsKey('tax_amount'), false);
    expect(json.containsKey('tax_rate'), false);
    expect(json.containsKey('tax_inclusive'), false);
  });
}
