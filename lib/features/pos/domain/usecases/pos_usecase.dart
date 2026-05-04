import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/domain/repositories/pos_repository.dart';
import 'package:fpdart/fpdart.dart';

class PosUseCase {
  final PosRepository repository;

  PosUseCase({
    required this.repository,
  });

  Future<Either<String?, PosSubmitResult>> submitSale({
    required String shopId,
    required String? customerId,
    required String paymentMethod,
    required List<PosCartItem> items,
    String discountAmount = '0',
    String taxAmount = '0',
  }) {
    return repository.submitSale(
      shopId: shopId,
      customerId: customerId,
      paymentMethod: paymentMethod,
      items: items,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
    );
  }
}