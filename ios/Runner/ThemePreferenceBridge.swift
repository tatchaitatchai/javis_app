import Flutter
import Foundation

/// Keeps the chosen theme in UserDefaults. The value is a plain preference.
final class ThemePreferenceBridge {
  private static let key = "com.javis.home.theme"
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.javis.home/theme", binaryMessenger: messenger)
  }

  func register() {
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "read":
        result(UserDefaults.standard.string(forKey: Self.key))
      case "write":
        guard let mode = (call.arguments as? [String: Any])?["mode"] as? String else {
          result(FlutterError(code: "invalidArguments", message: "Mode is missing", details: nil))
          return
        }
        UserDefaults.standard.set(mode, forKey: Self.key)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
