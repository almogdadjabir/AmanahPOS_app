import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/features/pos/data/datasources/pos_remote_data_source.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sales_queue.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/data/model/requests/create_sale_request_dto.dart';
import 'package:amana_pos/features/pos/domain/repositories/pos_repository.dart';
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
    String taxAmount = '0',
  }) async {
    try {
      if (items.isEmpty) {
        return const Left('Cart is empty');
      }

      final validItems = items.where((item) => item.product.id != null).toList();

      if (validItems.isEmpty) {
        return const Left('No valid products in cart');
      }

      final clientSaleId = const Uuid().v4();

      final createSaleDto = _buildCreateSaleDto(
        clientSaleId: clientSaleId,
        shopId: shopId,
        customerId: customerId,
        paymentMethod: paymentMethod,
        items: validItems,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
      );

      final offlineSaleDto = _buildOfflineSaleDto(
        clientSaleId: clientSaleId,
        shopId: shopId,
        customerId: customerId,
        paymentMethod: paymentMethod,
        items: validItems,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
      );

      final isOnline = await _networkMonitor.isOnline;

      if (!isOnline) {
        await _offlineSalesQueue.enqueueSale(offlineSaleDto);
        return Right(PosSubmitResult.offlineQueued(clientSaleId));
      }

      try {
        final result = await _remoteDataSource.createSale(createSaleDto);
        return Right(result);
      } catch (_) {
        await _offlineSalesQueue.enqueueSale(offlineSaleDto);
        return Right(PosSubmitResult.offlineQueued(clientSaleId));
      }
    } catch (e) {
      return Left(e.toString());
    }
  }

  CreateSaleRequestDto _buildCreateSaleDto({
    required String clientSaleId,
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    required String discountAmount,
    required String taxAmount,
  }) {
    return CreateSaleRequestDto(
      clientSaleId: clientSaleId,
      shop: shopId,
      customer: customerId,
      paymentMethod: paymentMethod,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      items: items.map((item) {
        return CreateSaleItemDto(
          productId: item.product.id!,
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
    required String taxAmount,
  }) {
    final subtotal = items.fold<double>(
      0,
          (sum, item) => sum + item.lineTotal,
    );

    final total = subtotal -
        (double.tryParse(discountAmount) ?? 0) +
        (double.tryParse(taxAmount) ?? 0);

    return OfflineSaleDto(
      clientSaleId: clientSaleId,
      shopId: shopId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      subtotal: subtotal.toStringAsFixed(2),
      total: total.toStringAsFixed(2),
      createdAt: DateTime.now().toUtc(),
      items: items.map((cartItem) {
        final product = cartItem.product;
        final price = cartItem.price;
        final quantity = cartItem.quantity.toDouble();

        return OfflineSaleItemDto(
          productId: product.id!,
          productName: product.name ?? '',
          quantity: quantity,
          unitPrice: price.toStringAsFixed(2),
          lineTotal: (price * quantity).toStringAsFixed(2),
          productSnapshot: product,
        );
      }).toList(),
    );
  }
}