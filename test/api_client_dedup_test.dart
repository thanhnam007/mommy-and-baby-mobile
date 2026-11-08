import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mommy_baby/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient In-Flight & Deduplication Tests', () {
    test('activeRequestsNotifier tracks initial state', () {
      final client = ApiClient();
      expect(client.activeRequestsNotifier.value, greaterThanOrEqualTo(0));
    });

    test('Duplicate mutating request with identical path and body is rejected', () async {
      final client = ApiClient();
      final dio = client.dio;

      // Adapter that stalls responses to test concurrency
      dio.httpClientAdapter = _StallingHttpClientAdapter();

      // Dispatch first mutating request
      final req1 = dio.post('/test-dedup', data: {'action': 'feeding', 'ml': 120});

      // Dispatch duplicate identical mutating request immediately while first is in-flight
      expect(
        () async => await dio.post('/test-dedup', data: {'action': 'feeding', 'ml': 120}),
        throwsA(isA<DioException>().having(
          (e) => e.type,
          'type',
          equals(DioExceptionType.cancel),
        )),
      );

      // Clean up req1
      try {
        await req1;
      } catch (_) {}
    });
  });
}

class _StallingHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    // Stall for 100ms
    await Future.delayed(const Duration(milliseconds: 100));
    return ResponseBody.fromString('{"ok": true}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
