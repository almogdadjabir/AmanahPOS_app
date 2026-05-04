import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:sqflite/sqflite.dart';

enum OfflineSaleStatus {
  pending,
  syncing,
  synced,
  failed,
}

class OfflineSalesQueue {
  OfflineSalesQueue({
    required OfflineDb db,
  })  : _db = db;

  final OfflineDb _db;

  Future<void> enqueueSale(OfflineSaleDto sale) async {
    final database = await _db.database;

    await database.transaction((txn) async {
      await txn.insert(
        'pending_sales',
        {
          'client_sale_id': sale.clientSaleId,
          'server_sale_id': null,
          'shop_id': sale.shopId,
          'customer_id': sale.customerId,
          'payment_method': sale.paymentMethod,
          'discount_amount': sale.discountAmount,
          'tax_amount': sale.taxAmount,
          'subtotal': sale.subtotal,
          'total': sale.total,
          'status': OfflineSaleStatus.pending.name,
          'error_message': null,
          'created_at': sale.createdAt.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'synced_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final item in sale.items) {
        await txn.insert(
          'pending_sale_items',
          {
            'client_sale_id': sale.clientSaleId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'line_total': item.lineTotal,
            'product_snapshot_json': jsonEncode(_productSnapshotToJson(item.productSnapshot)),
          },
        );

        await txn.rawUpdate(
          '''
          UPDATE stock
          SET quantity = MAX(quantity - ?, 0)
          WHERE product_id = ? AND shop_id = ?
          ''',
          [item.quantity, item.productId, sale.shopId],
        );

        await txn.rawUpdate(
          '''
          UPDATE products
          SET stock_level = MAX(COALESCE(stock_level, 0) - ?, 0)
          WHERE id = ?
          ''',
          [item.quantity, item.productId],
        );
      }
    });
  }

  Future<List<OfflineSaleDto>> getPendingSales({int limit = 20}) async {
    final db = await _db.database;

    final saleRows = await db.query(
      'pending_sales',
      where: 'status IN (?, ?)',
      whereArgs: [OfflineSaleStatus.pending.name, OfflineSaleStatus.failed.name],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    final sales = <OfflineSaleDto>[];

    for (final row in saleRows) {
      final clientSaleId = row['client_sale_id'] as String;

      final itemRows = await db.query(
        'pending_sale_items',
        where: 'client_sale_id = ?',
        whereArgs: [clientSaleId],
      );

      sales.add(
        OfflineSaleDto(
          clientSaleId: clientSaleId,
          shopId: row['shop_id'] as String,
          customerId: row['customer_id'] as String?,
          paymentMethod: row['payment_method'] as String,
          discountAmount: row['discount_amount']?.toString() ?? '0',
          taxAmount: row['tax_amount']?.toString() ?? '0',
          subtotal: row['subtotal'] as String,
          total: row['total'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          items: itemRows.map((itemRow) {
            final snapshot = jsonDecode(itemRow['product_snapshot_json'] as String);
            return OfflineSaleItemDto(
              productId: itemRow['product_id'] as String,
              productName: itemRow['product_name']?.toString() ?? '',
              quantity: (itemRow['quantity'] as num).toDouble(),
              unitPrice: itemRow['unit_price'] as String,
              lineTotal: itemRow['line_total'] as String,
              productSnapshot: ProductData.fromJson(snapshot),
            );
          }).toList(),
        ),
      );
    }

    return sales;
  }

  Future<void> markSyncing(String clientSaleId) async {
    await _updateStatus(clientSaleId, OfflineSaleStatus.syncing);
  }

  Future<void> markSynced({
    required String clientSaleId,
    required String? serverSaleId,
  }) async {
    final db = await _db.database;
    await db.update(
      'pending_sales',
      {
        'server_sale_id': serverSaleId,
        'status': OfflineSaleStatus.synced.name,
        'error_message': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'synced_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'client_sale_id = ?',
      whereArgs: [clientSaleId],
    );
  }

  Future<void> markFailed({
    required String clientSaleId,
    required String error,
  }) async {
    final db = await _db.database;
    await db.update(
      'pending_sales',
      {
        'status': OfflineSaleStatus.failed.name,
        'error_message': error,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'client_sale_id = ?',
      whereArgs: [clientSaleId],
    );
  }

  Future<int> pendingCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM pending_sales 
      WHERE status IN (?, ?, ?)
      ''',
      [
        OfflineSaleStatus.pending.name,
        OfflineSaleStatus.syncing.name,
        OfflineSaleStatus.failed.name,
      ],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _updateStatus(String clientSaleId, OfflineSaleStatus status) async {
    final db = await _db.database;
    await db.update(
      'pending_sales',
      {
        'status': status.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'client_sale_id = ?',
      whereArgs: [clientSaleId],
    );
  }

  Map<String, dynamic> _productSnapshotToJson(ProductData data) {
    return {
      'id': data.id,
      'category': data.category,
      'category_name': data.categoryName,
      'name': data.name,
      'description': data.description,
      'sku': data.sku,
      'barcode': data.barcode,
      'price': data.price,
      'cost_price': data.costPrice,
      'image': data.image,
      'unit': data.unit,
      'is_active': data.isActive,
      'track_inventory': data.trackInventory,
      'min_stock_level': data.minStockLevel,
      'stock_level': data.stockLevel,
      'created_at': data.createdAt,
      'thumbnail_url': data.thumbnailUrl,
    };
  }
}