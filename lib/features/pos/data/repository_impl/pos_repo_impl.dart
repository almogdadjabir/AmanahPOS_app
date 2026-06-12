import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/features/pos/data/datasources/pos_remote_data_source.dart';
import 'package:amana_pos/features/pos/data/datasources/pos_submit_exception.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sales_queue.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/data/model/requests/create_sale_request_dto.dart';
import 'package:amana_pos/features/pos/domain/repositories/pos_repository.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

class PosRepoImpl extends PosRepository {
  PosRepoImpl({
    required NetworkMonitor networkMonitor,
    required OfflineSalesQueue offlineSalesQueue,
    required PosRemoteDataSource remoteDataSource,
  })  : _networkMonitor = networkMonitor,
        _offlineSalesQueue = offlineSalesQueue,
        _remoteDataSource = remoteDataSource;

  final NetworkMonitor _networkMonitor;
  final OfflineSalesQueue _offlineSalesQueue;
  final PosRemoteDataSource _remoteDataSource;

  @override
  Future<Either<String?, PosSubmitResult>> submitSale({
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    String discountAmount = '0',
    TaxConfig taxConfig = const TaxConfig.disabled(),
  }) async {
    final validationError = _validateSaleInput(
      shopId: shopId,
      paymentMethod: paymentMethod,
      items: items,
    );

    if (validationError != null) {
      return Left(validationError);
    }

    final validItems = items.where((item) => item.product.id != null).toList();
    final clientSaleId = const Uuid().v4();

    final createSaleDto = _buildCreateSaleDto(
      clientSaleId: clientSaleId,
      shopId: shopId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      items: validItems,
      discountAmount: discountAmount,
    );

    final isOnline = await _networkMonitor.isOnline;

    if (!isOnline) {
      return _queueOfflineSale(
        clientSaleId: clientSaleId,
        shopId: shopId,
        customerId: customerId,
        paymentMethod: paymentMethod,
        items: validItems,
        discountAmount: discountAmount,
        taxConfig: taxConfig,
      );
    }

    try {
      final result = await _remoteDataSource.createSale(createSaleDto);
      return Right(result);
    } on PosSubmitException catch (e) {
      if (!e.canQueueOffline) {
        return Left(e.message);
      }

      return _queueOfflineSale(
        clientSaleId: clientSaleId,
        shopId: shopId,
        customerId: customerId,
        paymentMethod: paymentMethod,
        items: validItems,
        discountAmount: discountAmount,
        taxConfig: taxConfig,
      );
    } catch (_) {
      return const Left('Failed to submit sale. Please try again.');
    }
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

  Future<Either<String?, PosSubmitResult>> _queueOfflineSale({
    required String clientSaleId,
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    required String discountAmount,
    required TaxConfig taxConfig,
  }) async {
    final offlineSaleDto = _buildOfflineSaleDto(
      clientSaleId: clientSaleId,
      shopId: shopId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      items: items,
      discountAmount: discountAmount,
      taxConfig: taxConfig,
    );

    await _offlineSalesQueue.enqueueSale(offlineSaleDto);

    return Right(PosSubmitResult.offlineQueued(clientSaleId));
  }

  CreateSaleRequestDto _buildCreateSaleDto({
    required String clientSaleId,
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    required String discountAmount,
  }) {
    return CreateSaleRequestDto(
      clientSaleId: clientSaleId,
      shop: shopId,
      customer: customerId,
      paymentMethod: paymentMethod,
      discountAmount: discountAmount,
      items: items.map((item) {
        return CreateSaleItemDto(
          productId: item.product.id!.trim(),
          quantity: item.quantity.toString(),
          unitPrice: item.price.toStringAsFixed(2),
        );
      }).toList(),
    );
  }

  OfflineSaleDto _buildOfflineSaleDto({
    required String clientSaleId,
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    required String discountAmount,
    required TaxConfig taxConfig,
  }) {
    final subtotal = items.fold<double>(
      0,
          (sum, item) => sum + item.lineTotal,
    );

    final discount = double.tryParse(discountAmount) ?? 0;
    // Local preview of what the server will compute at sync time. In
    // inclusive mode, tax is extracted from (not added to) the taxable
    // amount, so the stored total equals subtotal − discount and can be
    // <= subtotal even when taxAmount > 0.
    final computation = TaxCalculator.compute(
      taxableAmount: subtotal - discount,
      config: taxConfig,
    );

    return OfflineSaleDto(
      clientSaleId: clientSaleId,
      shopId: shopId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      discountAmount: discountAmount,
      taxAmount: computation.taxAmount.toStringAsFixed(2),
      subtotal: subtotal.toStringAsFixed(2),
      total: computation.netAmount.toStringAsFixed(2),
      createdAt: DateTime.now().toUtc(),
      items: items.map((cartItem) {
        final price = cartItem.price;
        final quantity = cartItem.quantity.toDouble();

        return OfflineSaleItemDto(
          productId: cartItem.product.id!.trim(),
          productName: cartItem.product.name ?? '',
          quantity: quantity,
          unitPrice: price.toStringAsFixed(2),
          lineTotal: (price * quantity).toStringAsFixed(2),
          productSnapshot: cartItem.product,
        );
      }).toList(),
    );
  }
}