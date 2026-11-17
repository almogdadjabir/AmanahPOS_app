import 'package:fpdart/fpdart.dart';

import 'catalog_support.dart';

/// Runs a local catalog write (category / product / vendor service) for a
/// repository: a local refusal ([CatalogValidationException]) is its
/// message; anything else is a generic failure (the write rolled back).
Future<Either<String, T>> catalogResult<T>(Future<T> Function() write) async {
  try {
    return Right(await write());
  } on CatalogValidationException catch (e) {
    return Left(e.message);
  } catch (_) {
    return const Left('Failed to save the change. Please try again.');
  }
}
