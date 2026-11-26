import 'package:amana_pos/features/pairing/domain/pairing_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _dio(Response<dynamic> Function(RequestOptions) answer) {
  final d = Dio();
  d.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) {
        final r = answer(o);
        if ((r.statusCode ?? 200) >= 400) {
          h.reject(
            DioException(requestOptions: o, response: r, type: DioExceptionType.badResponse),
          );
        } else {
          h.resolve(r);
        }
      },
    ),
  );
  return d;
}

Response<dynamic> _r(RequestOptions o, int code, Object? data) =>
    Response(requestOptions: o, statusCode: code, data: data);

void main() {
  test('create reads the code and sends the business', () async {
    Object? sent;
    final s = PairingService(
      _dio((o) {
        sent = o.data;
        return _r(o, 201, {
          'success': true,
          'data': {
            'pairing_id': 'abc',
            'code': '123456',
            'expires_at': '2026-01-01T09:05:00Z',
            'ttl_seconds': 300,
            'business_name': 'Shop',
          },
        });
      }),
    );
    final c = await s.create(businessId: 'b1');
    expect(c.code, '123456');
    expect(c.pairingId, 'abc');
    expect(sent, {'business_id': 'b1'});
  });

  test('429 becomes rateLimited, 403 forbidden', () async {
    final s = PairingService(_dio((o) => _r(o, 429, {})));
    await expectLater(
      s.create(),
      throwsA(
        isA<PairingException>().having(
          (e) => e.failure,
          'failure',
          PairingFailure.rateLimited,
        ),
      ),
    );
    final f = PairingService(_dio((o) => _r(o, 403, {})));
    await expectLater(
      f.create(),
      throwsA(
        isA<PairingException>().having(
          (e) => e.failure,
          'failure',
          PairingFailure.forbidden,
        ),
      ),
    );
  });

  test('status reads state and device name', () async {
    final s = PairingService(
      _dio(
        (o) => _r(o, 200, {
          'data': {'status': 'used', 'device_name': 'Counter 1'},
        }),
      ),
    );
    final p = await s.status('abc');
    expect(p.status, PairingStatus.used);
    expect(p.deviceName, 'Counter 1');
  });
}
