/// Why a backend call failed. [code] is the API's error code, or one of the
/// two below. Screens never show it: see `AppLocalizations.failure`.
class BackendFailure implements Exception {
  const BackendFailure(this.code, {this.retryAfter});

  static const offline = 'offline';
  static const unknown = 'unknown';

  final String code;
  final Duration? retryAfter;

  @override
  String toString() => 'BackendFailure($code)';
}
