import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/features/returns/domain/refund_service.dart';
import 'package:amana_pos/features/returns/domain/repositories/returns_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Local-first: the refund is saved on the device and queued for sync, so it
/// works with no connection. There is no REST refund call any more.
class ReturnsRepoImpl extends ReturnsRepository {
  ReturnsRepoImpl({required RefundService refunds}) : _refunds = refunds;

  final RefundService _refunds;

  @override
  Future<Either<String?, RefundResponseDto>> processRefund({
    required String saleId,
    required RefundRequestDto request,
  }) async {
    try {
      final reference = await _refunds.refund(
        saleId: saleId,
        quantitiesByLineId: {
          for (final i in request.items)
            i.itemId: _qty(i.quantity),
        },
        method: request.method,
        reason: request.notes,
      );
      final r = await _refunds.receiptFor(reference);
      return Right(
        RefundResponseDto(
          success: true,
          refundReference: r.reference,
          refundTotal: r.total,
          returnedItems: [
            for (final i in r.items)
              ReturnedItems(
                productId: i.productId,
                productName: i.productName,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                subtotal: i.subtotal,
              ),
          ],
          sale: Sale(status: r.fullRefund ? 'refunded' : 'partial_refund'),
        ),
      );
    } on RefundValidationException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Exact thousandths text of a bloc quantity (already rounded to 3 dp).
  static String _qty(double q) => q.toStringAsFixed(3);
}
