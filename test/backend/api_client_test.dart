import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:javis_app/backend/api_backend.dart';
import 'package:javis_app/backend/api_client.dart';
import 'package:javis_app/backend/backend_failure.dart';
import 'package:javis_app/backend/session_vault.dart';

class _MemoryVault implements SessionVault {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

typedef _Handler = Future<void> Function(HttpRequest request);

void main() {
  late HttpServer server;
  late ApiClient api;
  late _Handler handle;

  void reply(HttpRequest request, int status, Object? body) {
    request.response.statusCode = status;
    if (body != null) request.response.write(jsonEncode(body));
    request.response.close();
  }

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) => handle(request));
    api = ApiClient(Uri.parse('http://127.0.0.1:${server.port}'));
  });

  tearDown(() => server.close(force: true));

  test('sends the token and decodes the body', () async {
    String? seen;
    handle = (request) async {
      seen = request.headers.value(HttpHeaders.authorizationHeader);
      reply(request, 200, {'ok': true});
    };
    api.token = 'token-value';
    expect(await api.get('/v1/me'), {'ok': true});
    expect(seen, 'Bearer token-value');
  });

  test('turns an API error into its code and Retry-After', () async {
    handle = (request) async {
      request.response.headers.set(HttpHeaders.retryAfterHeader, '120');
      reply(request, 429, {
        'error': {'code': 'rate_limited', 'message': 'Slow down'},
      });
    };
    await expectLater(
      api.post('/v1/auth/otp/request', {}),
      throwsA(
        isA<BackendFailure>()
            .having((failure) => failure.code, 'code', 'rate_limited')
            .having(
              (failure) => failure.retryAfter,
              'retryAfter',
              const Duration(minutes: 2),
            ),
      ),
    );
  });

  test('a body that is not JSON is an unknown failure', () async {
    handle = (request) async {
      request.response.statusCode = 502;
      request.response.write('<html>Bad gateway</html>');
      await request.response.close();
    };
    await expectLater(
      api.get('/v1/me'),
      throwsA(
        isA<BackendFailure>().having(
          (failure) => failure.code,
          'code',
          BackendFailure.unknown,
        ),
      ),
    );
  });

  test('no server is an offline failure', () async {
    await server.close(force: true);
    await expectLater(
      api.get('/v1/me'),
      throwsA(
        isA<BackendFailure>().having(
          (failure) => failure.code,
          'code',
          BackendFailure.offline,
        ),
      ),
    );
  });

  group('session', () {
    Map<String, dynamic> user({String? name}) => {
      'id': 'user-1',
      'phone': '+66812345678',
      'name': name,
    };

    test('verifying stores the token and returns a local phone', () async {
      final vault = _MemoryVault();
      final backend = ApiBackend(api, vault);
      handle = (request) async => reply(request, 200, {
        'token': 'stored-token',
        'expires_at': '2027-01-01T00:00:00Z',
        'user': user(),
      });
      final account = await backend.verifyCode('0812345678', '123456');
      expect(account.phone, '0812345678');
      expect(account.name, isNull);
      expect(vault.token, 'stored-token');
    });

    test('a rejected stored session is cleared', () async {
      final vault = _MemoryVault()..token = 'old-token';
      var expired = false;
      final backend = ApiBackend(api, vault)
        ..onSessionExpired = () => expired = true;
      handle = (request) async => reply(request, 401, {
        'error': {'code': 'unauthorized', 'message': 'Please sign in'},
      });
      expect(await backend.restoreSession(), isNull);
      expect(vault.token, isNull);
      expect(expired, isTrue);
    });

    test('offline keeps the stored session for a retry', () async {
      final vault = _MemoryVault()..token = 'kept-token';
      final backend = ApiBackend(api, vault);
      await server.close(force: true);
      await expectLater(
        backend.restoreSession(),
        throwsA(isA<BackendFailure>()),
      );
      expect(vault.token, 'kept-token');
    });

    test('a wrong code does not end a session', () async {
      final vault = _MemoryVault();
      var expired = false;
      final backend = ApiBackend(api, vault)
        ..onSessionExpired = () => expired = true;
      handle = (request) async => reply(request, 401, {
        'error': {'code': 'invalid_code', 'message': 'Wrong'},
      });
      await expectLater(
        backend.verifyCode('0812345678', '000000'),
        throwsA(isA<BackendFailure>()),
      );
      expect(expired, isFalse);
    });

    test('sign-out clears the token even when the server is gone', () async {
      final vault = _MemoryVault()..token = 'token-value';
      final backend = ApiBackend(api, vault);
      api.token = 'token-value';
      await server.close(force: true);
      await backend.signOut();
      expect(vault.token, isNull);
      expect(api.token, isNull);
    });
  });
}
