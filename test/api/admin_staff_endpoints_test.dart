import 'package:cine_book/api/api_client.dart';
import 'package:cine_book/models/admin_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          if (call.method == 'read') return null;
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  late APIClient apiClient;
  late DioAdapter dioAdapter;

  setUp(() {
    apiClient = APIClient();
    dioAdapter = DioAdapter(
      dio: apiClient.dio,
      matcher: const UrlRequestMatcher(),
    );
  });

  group('admin CRUD endpoints', () {
    test('creates an admin movie with the expected payload', () async {
      final request = MovieManagementRequest(
        title: 'CineLuxe Test',
        description: 'Admin created movie',
        genres: const ['Action'],
        durationMinutes: 120,
        director: 'Director',
        cast: const ['Actor'],
        posterUrl: 'https://example.com/poster.jpg',
        trailerUrl: 'https://example.com/trailer.mp4',
        ageRating: 'C13',
        releaseDate: DateTime.utc(2026, 6, 19),
        status: 'nowShowing',
      );

      dioAdapter.onPost(
        '/api/admin/movies',
        data: request.toJson(),
        (server) => server.reply(201, {
          'id': 'movie-1',
          ...request.toJson(),
          'rating': 0,
        }),
      );

      final movie = await apiClient.createAdminMovie(request);

      expect(movie.id, 'movie-1');
      expect(movie.title, 'CineLuxe Test');
      expect(movie.status, 'nowShowing');
    });

    test('updates room status through admin maintenance endpoint', () async {
      dioAdapter.onPatch(
        '/api/admin/rooms/room-1/status',
        data: {'status': 'maintenance'},
        (server) => server.reply(200, {
          'id': 'room-1',
          'theaterId': 'theater-1',
          'name': 'Room 1',
          'status': 'maintenance',
          'totalSeats': 80,
          'screenType': 'IMAX',
        }),
      );

      final room = await apiClient.updateAdminRoomStatus(
        'room-1',
        'maintenance',
      );

      expect(room.status, 'maintenance');
      expect(room.totalSeats, 80);
    });

    test('lists admin users with role filter and pagination', () async {
      dioAdapter.onGet(
        '/api/admin/users',
        queryParameters: {'page': 1, 'pageSize': 10, 'role': 'staff'},
        (server) => server.reply(200, {
          'data': [
            {
              'userId': 'staff-1',
              'fullName': 'Staff One',
              'email': 'staff@cineluxe.vn',
              'role': 'staff',
              'active': true,
              'permissions': ['Soát vé', 'Quản lý phòng'],
            },
          ],
          'page': 1,
          'pageSize': 10,
          'totalItems': 1,
          'totalPages': 1,
          'hasNext': false,
          'hasPrevious': false,
        }),
      );

      final users = await apiClient.getAdminUsers(role: 'staff', pageSize: 10);

      expect(users.data.single.userId, 'staff-1');
      expect(users.data.single.permissions, contains('Quản lý phòng'));
    });
  });

  group('staff operations endpoints', () {
    test('reports room maintenance issue', () async {
      const request = RoomMaintenanceRequest(
        staffId: 'staff-1',
        reason: 'projector',
        description: 'Projector is flickering',
      );

      dioAdapter.onPost(
        '/api/staff/rooms/room-1/maintenance',
        data: request.toJson(),
        (server) => server.reply(200, {
          'id': 'issue-1',
          'staffId': 'staff-1',
          'roomId': 'room-1',
          'description': 'Projector is flickering',
          'status': 'Đã gửi Admin',
          'createdAt': '2026-06-19T10:00:00.000Z',
        }),
      );

      final issue = await apiClient.reportRoomMaintenance('room-1', request);

      expect(issue.id, 'issue-1');
      expect(issue.status, 'Đã gửi Admin');
    });

    test(
      'modifies booking seats and exposes additional payment state',
      () async {
        const request = ModifySeatsRequest(
          staffId: 'staff-1',
          newSeatCodes: ['B1', 'B2'],
        );

        dioAdapter.onPost(
          '/api/staff/bookings/BK-1/modify-seats',
          data: request.toJson(),
          (server) => server.reply(200, {
            'bookingId': 'BK-1',
            'status': 'pendingAdditionalPayment',
            'totalAmount': 300000,
            'priceDifference': 40000,
            'requiresAdditionalPayment': true,
            'paymentUrl': 'https://pay.example.test/BK-1',
          }),
        );

        final result = await apiClient.modifyBookingSeats('BK-1', request);

        expect(result.requiresAdditionalPayment, isTrue);
        expect(result.priceDifference, 40000);
        expect(result.paymentUrl, isNotNull);
      },
    );
  });

  group('payment settings endpoints', () {
    test('gets masked VNPay payment settings', () async {
      dioAdapter.onGet(
        '/api/admin/settings/payment',
        (server) => server.reply(200, {
          'terminalId': 'ABC12345',
          'secretKey': '****************************7890',
          'environment': 'sandbox',
          'returnUrl': 'cineluxe://payment-return',
          'enabled': true,
        }),
      );

      final settings = await apiClient.getPaymentSettings();

      expect(settings.terminalId, 'ABC12345');
      expect(settings.secretKey.endsWith('7890'), isTrue);
    });

    test('updates VNPay settings with full secret payload', () async {
      const request = UpdatePaymentSettingsRequest(
        terminalId: 'ABC12345',
        secretKey: '12345678901234567890123456789012',
        environment: 'sandbox',
        returnUrl: 'cineluxe://payment-return',
        enabled: true,
      );

      dioAdapter.onPut(
        '/api/admin/settings/payment',
        data: request.toJson(),
        (server) => server.reply(200, {
          'terminalId': 'ABC12345',
          'secretKey': '****************************9012',
          'environment': 'sandbox',
          'returnUrl': 'cineluxe://payment-return',
          'enabled': true,
        }),
      );

      final settings = await apiClient.updatePaymentSettings(request);

      expect(settings.secretKey, '****************************9012');
      expect(settings.enabled, isTrue);
    });
  });
}
