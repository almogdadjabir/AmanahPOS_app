import 'dart:convert';

import 'package:amana_pos/core/sync/catalog_result.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/add_customer_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/domain/customer_service.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Local-first: reads the `customers` table, writes go through
/// [CustomerService] (row + outbox in one transaction). No REST call.
class CustomerRepoImpl extends CustomerRepository {
  CustomerRepoImpl({
    required LocalWriter writer,
    required CustomerService Function() service,
  }) : _writer = writer,
       _service = service;

  final LocalWriter _writer;
  final CustomerService Function() _service;

  @override
  Future<Either<String?, CustomerResponseDto>> getCustomers({
    required int page,
    required int pageSize,
    String search = '',
    CustomerActiveFilter isActive = CustomerActiveFilter.active,
  }) async {
    try {
      final q = search.trim();
      final all = await _writer.read((db) async {
        final marks = await CatalogSyncMarks.load(
          db,
          CustomerService.entity,
          scope: SyncScope.current,
        );
        final rows = await db.query(
          'customers',
          where: q.isEmpty
              ? null
              : "name LIKE ? ESCAPE '\\' OR phone LIKE ? ESCAPE '\\' "
                    "OR email LIKE ? ESCAPE '\\'",
          whereArgs: q.isEmpty ? null : List.filled(3, _like(q)),
          orderBy: 'name COLLATE NOCASE ASC, id ASC',
        );
        return [for (final r in rows) _data(r, marks)];
      });
      final filtered = [
        for (final c in all)
          if (switch (isActive) {
            CustomerActiveFilter.active => c.isActive != false,
            CustomerActiveFilter.inactive => c.isActive == false,
            CustomerActiveFilter.all => true,
          })
            c,
      ];
      final start = (page - 1) * pageSize;
      final slice = start >= filtered.length
          ? <CustomerData>[]
          : filtered.sublist(
              start,
              (start + pageSize).clamp(0, filtered.length),
            );
      final pages = (filtered.length / pageSize).ceil();
      return Right(
        CustomerResponseDto(
          count: filtered.length,
          totalPages: pages == 0 ? 1 : pages,
          currentPage: page,
          next: page < pages ? '${page + 1}' : null,
          previous: page > 1 ? '${page - 1}' : null,
          results: slice,
        ),
      );
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String?, AddCustomerResponseDto>> createCustomer({
    required CustomerRequestDto request,
  }) async {
    final r = await catalogResult(
      () => _service().create(
        name: request.name,
        phone: request.phone,
        email: request.email,
        address: request.address,
        notes: request.notes,
      ),
    );
    return r.fold(Left.new, (id) => _reload(id));
  }

  @override
  Future<Either<String?, AddCustomerResponseDto>> updateCustomer({
    required String customerId,
    required CustomerRequestDto request,
  }) async {
    final r = await catalogResult(() async {
      await _service().update(
        customerId,
        name: request.name,
        phone: request.phone ?? '',
        email: request.email ?? '',
        address: request.address ?? '',
        notes: request.notes ?? '',
      );
      if (request.isActive != null) {
        await _service().setActive(customerId, request.isActive!);
      }
      return customerId;
    });
    return r.fold(Left.new, (id) => _reload(id));
  }

  @override
  Future<Either<String?, AddCustomerResponseDto>> setCustomerActive({
    required String customerId,
    required bool isActive,
  }) async {
    final r = await catalogResult(() async {
      await _service().setActive(customerId, isActive);
      return customerId;
    });
    return r.fold(Left.new, (id) => _reload(id));
  }

  Future<Either<String?, AddCustomerResponseDto>> _reload(String id) async {
    try {
      final data = await _writer.read((db) async {
        final marks = await CatalogSyncMarks.load(
          db,
          CustomerService.entity,
          scope: SyncScope.current,
        );
        final rows = await db.query(
          'customers',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        return rows.isEmpty ? null : _data(rows.first, marks);
      });
      return Right(AddCustomerResponseDto(success: true, data: data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  static String _like(String q) =>
      '%${q.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')}%';

  static CustomerData _data(Map<String, Object?> r, CatalogSyncMarks marks) {
    final j = jsonDecode('${r['json']}') as Map<String, dynamic>;
    final id = r['id'] as String;
    return CustomerData(
      id: id,
      tenant: j['tenant']?.toString(),
      name: (j['name'] ?? r['name'])?.toString(),
      phone: j['phone']?.toString(),
      email: j['email']?.toString(),
      address: j['address']?.toString(),
      loyaltyPoints: j['loyalty_points'] is int
          ? j['loyalty_points'] as int
          : null,
      notes: j['notes']?.toString(),
      isActive: j['is_active'] is bool ? j['is_active'] as bool : true,
      totalPurchases: j['total_purchases']?.toString(),
      createdAt: j['created_at']?.toString(),
      updatedAt: j['updated_at']?.toString(),
      syncMark: switch (marks.markOf(id)) {
        CatalogSyncMark.synced => CustomerSyncMark.synced,
        CatalogSyncMark.pending => CustomerSyncMark.pending,
        CatalogSyncMark.failed => CustomerSyncMark.failed,
      },
    );
  }
}
