import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import '../../lib/api/api_client.dart';
import '../../lib/api/exceptions/api_exceptions.dart';

void main() {
  group('Simple Error Handling Test', () {
    late APIClient apiClient;
    late DioAdapter dioAdapter;
    
    setUp(() {
      apiClient = APIClient();
      apiClient.updateBaseUrl('https://test-api.example.com');
      dioAdapter = DioAdapter(dio: apiClient.dio);
    });
    
    test('400 Bad Request', () async {
      const path = '/api/test';
      final errorResponse = {
        'code': 'VALIDATION_ERROR',
        'message': 'Invalid request',
        'timestamp': '2024-01-01T00:00:00Z',
        'path': path,
      };
      
      dioAdapter.onGet(
        path,
        (server) => server.reply(400, errorResponse),
      );
      
      try {
        await apiClient.get(path);
        fail('Should throw exception');
      } catch (e) {
        print('Caught exception: ${e.runtimeType}');
        print('Exception: $e');
        
        expect(e, isA<DioException>());
        final dioError = e as DioException;
        expect(dioError.error, isA<ApiValidationException>());
      }
    });
    
    test('404 Not Found', () async {
      const path = '/api/missing';
      final errorResponse = {
        'code': 'NOT_FOUND',
        'message': 'Resource not found',
        'timestamp': '2024-01-01T00:00:00Z',
        'path': path,
      };
      
      dioAdapter.onGet(
        path,
        (server) => server.reply(404, errorResponse),
      );
      
      try {
        await apiClient.get(path);
        fail('Should throw exception');
      } catch (e) {
        print('Caught exception: ${e.runtimeType}');
        
        expect(e, isA<DioException>());
        final dioError = e as DioException;
        expect(dioError.error, isA<ApiNotFoundException>());
      }
    });
    
    test('500 Server Error', () async {
      const path = '/api/error';
      final errorResponse = {
        'code': 'SERVER_ERROR',
        'message': 'Internal server error',
        'timestamp': '2024-01-01T00:00:00Z',
        'path': path,
      };
      
      dioAdapter.onGet(
        path,
        (server) => server.reply(500, errorResponse),
      );
      
      try {
        await apiClient.get(path);
        fail('Should throw exception');
      } catch (e) {
        print('Caught exception: ${e.runtimeType}');
        
        expect(e, isA<DioException>());
        final dioError = e as DioException;
        expect(dioError.error, isA<ApiServerException>());
      }
    });
  });
}
