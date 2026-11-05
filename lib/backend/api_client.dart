import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'backend_failure.dart';

typedef Json = Map<String, dynamic>;

/// JSON over HTTP with the session token. Every failure becomes a
/// [BackendFailure]; the token and bodies are never logged.
class ApiClient {
  ApiClient(this._baseUrl, {HttpClient? client})
    : _client = client ?? HttpClient();

  static const _timeout = Duration(seconds: 15);

  final Uri _baseUrl;
  final HttpClient _client;

  String? token;
  VoidCallback? onUnauthorized;

  Future<Json> get(String path) => _send('GET', path);
  Future<Json> post(String path, [Json? body]) => _send('POST', path, body);
  Future<Json> patch(String path, Json body) => _send('PATCH', path, body);
  Future<Json> put(String path, Json body) => _send('PUT', path, body);
  Future<Json> delete(String path) => _send('DELETE', path);

  Future<Json> _send(String method, String path, [Json? body]) async {
    final HttpClientResponse response;
    final String text;
    try {
      final request = await _client
          .openUrl(method, _baseUrl.resolve(path))
          .timeout(_timeout);
      final token = this.token;
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      response = await request.close().timeout(_timeout);
      text = await utf8.decoder.bind(response).join().timeout(_timeout);
    } on SocketException {
      throw const BackendFailure(BackendFailure.offline);
    } on HttpException {
      throw const BackendFailure(BackendFailure.offline);
    } on TimeoutException {
      throw const BackendFailure(BackendFailure.offline);
    } on TlsException {
      throw const BackendFailure(BackendFailure.offline);
    }
    final json = _decode(text);
    if (response.statusCode < 300) return json;
    throw _failure(response, json);
  }

  Json _decode(String text) {
    if (text.isEmpty) return const {};
    try {
      final decoded = jsonDecode(text);
      if (decoded is Json) return decoded;
    } on FormatException {
      // Not JSON: a proxy page, for example. Reported as unknown below.
    }
    return const {};
  }

  BackendFailure _failure(HttpClientResponse response, Json json) {
    final error = json['error'];
    final code = error is Json ? error['code'] as String? : null;
    if (code == 'unauthorized') onUnauthorized?.call();
    final seconds = int.tryParse(
      response.headers.value(HttpHeaders.retryAfterHeader) ?? '',
    );
    return BackendFailure(
      code ?? BackendFailure.unknown,
      retryAfter: seconds == null ? null : Duration(seconds: seconds),
    );
  }
}
