import Flutter
import Foundation
import Security

/// Keeps the JAVIS session token in the Keychain, on this device only.
/// The token is never logged or included in an error.
final class SessionVaultBridge {
  private static let service = "com.javis.home.session"
  private static let account = "api"
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.javis.home/session", binaryMessenger: messenger)
  }

  func register() {
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "read":
        self.read(result)
      case "write":
        guard let token = (call.arguments as? [String: Any])?["token"] as? String else {
          result(FlutterError(code: "invalidArguments", message: "Token is missing", details: nil))
          return
        }
        self.write(token, result)
      case "clear":
        self.finish(SecItemDelete(self.query as CFDictionary), result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.service,
      kSecAttrAccount as String: Self.account,
    ]
  }

  private func read(_ result: FlutterResult) {
    var search = query
    search[kSecReturnData as String] = true
    search[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(search as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else {
      finish(status, result)
      return
    }
    result(String(data: data, encoding: .utf8))
  }

  private func write(_ token: String, _ result: FlutterResult) {
    SecItemDelete(query as CFDictionary)
    var item = query
    item[kSecValueData as String] = Data(token.utf8)
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    finish(SecItemAdd(item as CFDictionary, nil), result)
  }

  private func finish(_ status: OSStatus, _ result: FlutterResult) {
    if status == errSecSuccess || status == errSecItemNotFound {
      result(nil)
    } else {
      result(FlutterError(code: "keychain", message: "Keychain status \(status)", details: nil))
    }
  }
}
