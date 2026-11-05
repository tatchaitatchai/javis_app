import 'api_backend.dart';
import 'api_client.dart';
import 'demo_backend.dart';
import 'javis_backend.dart';
import 'session_vault.dart';

/// The API when `--dart-define=JAVIS_API_URL=…` is set, otherwise the demo.
JavisBackend createBackend() {
  const url = String.fromEnvironment('JAVIS_API_URL');
  if (url.isEmpty) return DemoBackend();
  return ApiBackend(ApiClient(Uri.parse(url)), KeychainSessionVault());
}
