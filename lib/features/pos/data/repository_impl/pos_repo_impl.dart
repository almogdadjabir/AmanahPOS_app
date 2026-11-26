import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/domain/repositories/pos_repository.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:fpdart/fpdart.dart';

class PosRepoImpl extends PosRepository {
  PosRepoImpl({required SaleService Function() saleService})
    : _saleService = saleService;

  /// Lazy so the sync core is only constructed on first sale.
  final SaleService Function() _saleService;

  /// Every sale is written locally (sale rows + outbox + stock, one txn) and
  /// never calls the network here; the sync engine pushes it later.
  @override
  Future<Either<String?, PosSubmitResult>> submitSale({
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    String discountAmount = '0',
    TaxConfig taxConfig = const TaxConfig.disabled(),
    List<SalePaymentPart>? payments,
  }) async {
    final validationError = _validateSaleInput(
      shopId: shopId,
      paymentMethod: paymentMethod,
      items: items,
    );

    if (validationError != null) {
      return Left(validationError);
    }

    return _saveLocalSale(
      shopId: shopId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      items: items,
      discountAmount: discountAmount,
      taxConfig: taxConfig,
      payments: payments,
    );
  }

  Future<Either<String?, PosSubmitResult>> _saveLocalSale({
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    required String discountAmount,
    required TaxConfig taxConfig,
    List<SalePaymentPart>? payments,
  }) async {
    final draft = SaleDraft(
      shopId: shopId.trim(),
      customerId: (customerId == null || customerId.trim().isEmpty)
          ? null
          : customerId.trim(),
      paymentMethod: paymentMethod.trim(),
      discountAmount: discountAmount,
      taxConfig: taxConfig,
      payments: payments,
      lines: [for (final item in items) _draftLine(item)],
    );
    try {
      final sale = await _saleService().createSale(draft);
      return Right(
        PosSubmitResult.localSaved(
          saleId: sale.id,
          receiptNumber: sale.displayReceiptNumber,
          taxAmount: sale.taxAmount,
          taxRate: sale.taxRate,
          taxInclusive: sale.taxInclusive,
          netAmount: sale.netAmount,
        ),
      );
    } on SaleProductUnavailableException {
      rethrow; // PosBloc drops those lines and tells the cashier
    } on SaleValidationException catch (e) {
      return Left(e.message);
    } catch (_) {
      return const Left('Failed to save sale. Please try again.');
    }
  }

  static SaleDraftLine _draftLine(PosCartItem item) {
    final p = item.product;
    final price = (p.price == null || p.price!.trim().isEmpty)
        ? '0'
        : p.price!.trim();
    if (item.isCustom) {
      return SaleDraftLine.custom(
        name: p.name?.trim() ?? '',
        unitPrice: price,
        quantity: '${item.quantity}',
      );
    }
    return SaleDraftLine.product(
      productId: p.id!.trim(),
      productName: p.name ?? '',
      quantity: '${item.quantity}',
      unitPrice: price,
      unitCost: p.costPrice,
      discount: item.discountText,
      snapshot: {
        'id': p.id,
        'name': p.name,
        'sku': p.sku,
        'barcode': p.barcode,
        'price': p.price,
        'cost_price': p.costPrice,
        'unit': p.unit,
        'image': p.image,
        'category': p.category,
        'category_name': p.categoryName,
      },
    );
  }

  String? _validateSaleInput({
    required String shopId,
    required String paymentMethod,
    required List<PosCartItem> items,
  }) {
    if (shopId.trim().isEmpty) {
      return 'Shop is required';
    }

    if (paymentMethod.trim().isEmpty) {
      return 'Payment method is required';
    }

    if (items.isEmpty) {
      return 'Cart is empty';
    }

    final hasValidProduct = items.any((item) {
      final productId = item.product.id?.trim();
      return productId != null && productId.isNotEmpty;
    });

    if (!hasValidProduct) {
      return 'No valid products in cart';
    }

    final hasInvalidQuantity = items.any((item) => item.quantity <= 0);
    if (hasInvalidQuantity) {
      return 'Invalid product quantity';
    }

    return null;
  }
}
