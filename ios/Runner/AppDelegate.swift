import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var lightingBridge: JavisLightingBridge?
  private var sessionVault: SessionVaultBridge?
  private var themePreference: ThemePreferenceBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let bridge = JavisLightingBridge(
      messenger: engineBridge.applicationRegistrar.messenger(),
      adapter: makeLightingAdapter()
    )
    bridge.register()
    lightingBridge = bridge

    let vault = SessionVaultBridge(messenger: engineBridge.applicationRegistrar.messenger())
    vault.register()
    sessionVault = vault

    let theme = ThemePreferenceBridge(messenger: engineBridge.applicationRegistrar.messenger())
    theme.register()
    themePreference = theme
  }
}

enum LightingReadiness: String {
  case ready
  case configurationMissing
  case sdkUnavailable
  case sessionRequired
  case unsupportedSimulator
  case permissionDenied
  case transportFailure
}

struct LightingBridgeFailure: Error {
  let code: String
  let message: String
  let details: [String: Any]?

  func flutterError() -> FlutterError {
    FlutterError(code: code, message: message, details: details)
  }
}

/// Provider-neutral boundary. Native credentials and SDK objects stay behind it.
/// No Tuya types or credentials may cross this interface.
protocol LightingNativeAdapter {
  var readiness: LightingReadiness { get }
  var onEvent: (([String: Any]) -> Void)? { get set }

  func initialize() -> [String: Any]
  func prepareHome(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void)
  func preparePairing(completion: @escaping (Result<Void, LightingBridgeFailure>) -> Void)
  func pairingCapabilities() -> [String: Any]
  func currentWifi(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void)
  func discoverBulbHotspot(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void)
  func listBulbWifi(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void)
  func cancelSetup()
  func startDeviceScan() throws -> [String: Any]
  func stopDeviceScan()
  func refreshDevices(completion: @escaping (Result<[[String: Any]], LightingBridgeFailure>) -> Void)
  func startPairing(operationID: String, ssid: String, password: String, mode: String, deviceID: String?) throws
  func cancelPairing(operationID: String)
  func sendCommand(deviceID: String, command: [String: Any], completion: @escaping (Result<Void, LightingBridgeFailure>) -> Void)
  func removeDevice(deviceID: String, completion: @escaping (Result<[[String: Any]], LightingBridgeFailure>) -> Void)
}

/// Honest checked-in adapter used until the app-specific SmartLife SDK package exists locally.
final class UnavailableLightingAdapter: LightingNativeAdapter {
  var onEvent: (([String: Any]) -> Void)?
  var readiness: LightingReadiness {
    #if targetEnvironment(simulator)
      return .unsupportedSimulator
    #else
      return .sdkUnavailable
    #endif
  }

  func initialize() -> [String: Any] {
    [
      "readiness": readiness.rawValue,
      "devices": [],
    ]
  }

  func prepareHome(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void) {
    completion(.failure(unavailableFailure()))
  }

  func preparePairing(completion: @escaping (Result<Void, LightingBridgeFailure>) -> Void) {
    completion(.failure(unavailableFailure()))
  }

  func pairingCapabilities() -> [String: Any] {
    ["ezAvailable": false, "ezReason": readiness.rawValue]
  }

  func currentWifi(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void) {
    completion(.failure(unavailableFailure()))
  }

  func discoverBulbHotspot(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void) {
    completion(.failure(unavailableFailure()))
  }

  func listBulbWifi(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void) {
    completion(.failure(unavailableFailure()))
  }

  func cancelSetup() {}

  func startDeviceScan() throws -> [String: Any] {
    throw unavailableFailure()
  }

  func stopDeviceScan() {}

  func refreshDevices(completion: @escaping (Result<[[String: Any]], LightingBridgeFailure>) -> Void) {
    completion(.failure(unavailableFailure()))
  }

  func startPairing(operationID: String, ssid: String, password: String, mode: String, deviceID: String?) throws {
    throw unavailableFailure(operationID: operationID)
  }

  func cancelPairing(operationID: String) {}

  func sendCommand(deviceID: String, command: [String: Any], completion: @escaping (Result<Void, LightingBridgeFailure>) -> Void) {
    completion(.failure(unavailableFailure(deviceID: deviceID)))
  }

  func removeDevice(deviceID: String, completion: @escaping (Result<[[String: Any]], LightingBridgeFailure>) -> Void) {
    completion(.failure(unavailableFailure(deviceID: deviceID)))
  }

  private func unavailableFailure(
    operationID: String? = nil,
    deviceID: String? = nil
  ) -> LightingBridgeFailure {
    var details: [String: Any] = ["readiness": readiness.rawValue]
    details["operationId"] = operationID
    details["deviceId"] = deviceID

    switch readiness {
    case .unsupportedSimulator:
      return LightingBridgeFailure(
        code: "unsupportedSimulator",
        message: "Real bulb pairing and control require a physical iPhone.",
        details: details
      )
    case .sdkUnavailable:
      return LightingBridgeFailure(
        code: "sdkUnavailable",
        message: "The app-specific SmartLife iOS SDK package is not installed.",
        details: details
      )
    default:
      return LightingBridgeFailure(
        code: "transportFailure",
        message: "The native lighting provider is unavailable.",
        details: details
      )
    }
  }
}

private final class JavisLightingBridge: NSObject, FlutterStreamHandler {
  private static let methodChannelName = "com.javis.home/lighting"
  private static let eventChannelName = "com.javis.home/lighting/events"

  private var adapter: LightingNativeAdapter
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private var eventSink: FlutterEventSink?
  private var activeOperationID: String?

  init(messenger: FlutterBinaryMessenger, adapter: LightingNativeAdapter) {
    self.adapter = adapter
    methodChannel = FlutterMethodChannel(
      name: Self.methodChannelName,
      binaryMessenger: messenger
    )
    eventChannel = FlutterEventChannel(
      name: Self.eventChannelName,
      binaryMessenger: messenger
    )
    super.init()
  }

  func register() {
    adapter.onEvent = { [weak self] event in
      DispatchQueue.main.async {
        guard let self else { return }
        if event["type"] as? String == "pairing" {
          guard let id = event["operationId"] as? String, id == self.activeOperationID else { return }
          if ["success", "failed", "cancelled"].contains(event["status"] as? String ?? "") {
            self.activeOperationID = nil
          }
        }
        self.eventSink?(event)
      }
    }
    methodChannel.setMethodCallHandler { [weak self] call, flutterResult in
      guard let self else {
        flutterResult(
          FlutterError(
            code: "bridgeUnavailable",
            message: "The native lighting bridge is unavailable.",
            details: nil
          )
        )
        return
      }
      self.handle(call, result: flutterResult)
    }
    eventChannel.setStreamHandler(self)
  }

  private func handle(_ call: FlutterMethodCall, result flutterResult: @escaping FlutterResult) {
    let result = OneShotFlutterResult(flutterResult)

    switch call.method {
    case "initialize":
      let snapshot = adapter.initialize()
      emitReadiness()
      emitDevices(snapshot["devices"] as? [[String: Any]] ?? [])
      result.success(snapshot)

    case "prepareHome":
      adapter.prepareHome { [weak self] outcome in
        switch outcome {
        case .success(let snapshot):
          self?.emitReadiness()
          self?.emitDevices(snapshot["devices"] as? [[String: Any]] ?? [])
          result.success(snapshot)
        case .failure(let failure):
          self?.emitReadiness()
          result.failure(failure)
        }
      }

    case "preparePairing":
      adapter.preparePairing { outcome in
        switch outcome {
        case .success: result.success(["accepted": true])
        case .failure(let failure): result.failure(failure)
        }
      }

    case "pairingCapabilities":
      result.success(adapter.pairingCapabilities())

    case "currentWifi":
      adapter.currentWifi { outcome in
        switch outcome {
        case .success(let network): result.success(network)
        case .failure(let failure): result.failure(failure)
        }
      }

    case "discoverBulbHotspot":
      adapter.discoverBulbHotspot { outcome in
        switch outcome {
        case .success(let candidate): result.success(candidate)
        case .failure(let failure): result.failure(failure)
        }
      }

    case "listBulbWifi":
      adapter.listBulbWifi { outcome in
        switch outcome {
        case .success(let networks): result.success(networks)
        case .failure(let failure): result.failure(failure)
        }
      }

    case "cancelSetup":
      adapter.cancelSetup()
      result.success(["cancelled": true])

    case "startDeviceScan":
      do {
        result.success(try adapter.startDeviceScan())
      } catch let failure as LightingBridgeFailure {
        result.failure(failure)
      } catch {
        result.failure(code: "transportFailure", message: "The nearby device scan could not start.")
      }

    case "stopDeviceScan":
      adapter.stopDeviceScan()
      result.success(["stopped": true])

    case "refreshDevices":
      adapter.refreshDevices { [weak self] outcome in
        switch outcome {
        case .success(let devices):
          self?.emitDevices(devices)
          result.success(["devices": devices])
        case .failure(let failure):
          self?.emitReadiness()
          result.failure(failure)
        }
      }

    case "startPairing":
      guard let arguments = call.arguments as? [String: Any],
        let operationID = nonEmptyString(arguments["operationId"]),
        let ssid = arguments["ssid"] as? String, !ssid.isEmpty, ssid.utf8.count <= 32,
        let password = arguments["password"] as? String, !password.isEmpty, password.utf8.count <= 64,
        let mode = arguments["mode"] as? String, ["ap", "ez", "ble"].contains(mode)
      else {
        result.failure(
          code: "invalidArguments",
          message: "Provide an operation ID, supported pairing mode, and valid Wi-Fi credentials."
        )
        return
      }
      // A nearby Bluetooth device is identified only by its app-owned scan id.
      let deviceID = nonEmptyString(arguments["deviceId"])
      if mode == "ble" && deviceID == nil {
        result.failure(code: "invalidArguments", message: "Bluetooth pairing requires a nearby deviceId.")
        return
      }

      if let activeOperationID {
        result.failure(
          code: "operationInProgress",
          message: "Another pairing operation is already active.",
          details: ["activeOperationId": activeOperationID]
        )
        return
      }

      activeOperationID = operationID
      do {
        try adapter.startPairing(operationID: operationID, ssid: ssid, password: password,
          mode: mode, deviceID: deviceID)
        emitPairing(operationID: operationID, status: "searching")
        result.success(["operationId": operationID, "accepted": true])
      } catch let failure as LightingBridgeFailure {
        activeOperationID = nil
        result.failure(failure)
      } catch {
        activeOperationID = nil
        result.failure(
          code: "transportFailure",
          message: "The native lighting provider could not start pairing.",
          details: ["operationId": operationID]
        )
      }

    case "cancelPairing":
      guard let arguments = call.arguments as? [String: Any],
        let operationID = nonEmptyString(arguments["operationId"])
      else {
        result.failure(
          code: "invalidArguments",
          message: "cancelPairing requires a non-empty operationId."
        )
        return
      }

      let cancelled = activeOperationID == operationID
      if cancelled {
        // Invalidate first so any provider callback racing with cancellation is stale.
        activeOperationID = nil
        adapter.cancelPairing(operationID: operationID)
        emitPairing(operationID: operationID, status: "cancelled")
      }
      result.success(["operationId": operationID, "cancelled": cancelled])

    case "sendCommand":
      guard let arguments = call.arguments as? [String: Any],
        let deviceID = nonEmptyString(arguments["deviceId"]),
        let command = arguments["command"] as? [String: Any]
      else {
        result.failure(
          code: "invalidArguments",
          message: "sendCommand requires a non-empty deviceId and a command map."
        )
        return
      }

      adapter.sendCommand(deviceID: deviceID, command: command) { outcome in
        switch outcome {
        case .success:
          result.success(["deviceId": deviceID, "accepted": true])
        case .failure(let failure):
          result.failure(failure)
        }
      }

    case "removeDevice":
      guard let arguments = call.arguments as? [String: Any],
        let deviceID = nonEmptyString(arguments["deviceId"])
      else {
        result.failure(code: "invalidArguments", message: "removeDevice requires a non-empty deviceId.")
        return
      }
      adapter.removeDevice(deviceID: deviceID) { [weak self] outcome in
        switch outcome {
        case .success(let devices):
          self?.emitDevices(devices)
          result.success(["devices": devices])
        case .failure(let failure):
          result.failure(failure)
        }
      }

    default:
      result.notImplemented()
    }
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    emitReadiness()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func emitReadiness() {
    eventSink?([
      "type": "readiness",
      "readiness": adapter.readiness.rawValue,
    ])
  }

  private func emitDevices(_ devices: [[String: Any]]) {
    eventSink?([
      "type": "devices",
      "devices": devices,
    ])
  }

  private func emitPairing(operationID: String, status: String) {
    eventSink?([
      "type": "pairing",
      "operationId": operationID,
      "status": status,
    ])
  }

  private func nonEmptyString(_ value: Any?) -> String? {
    guard let value = value as? String,
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return nil
    }
    return value
  }
}

/// Makes method-channel completion idempotent as native SDK callbacks are added later.
private final class OneShotFlutterResult {
  private let lock = NSLock()
  private var callback: FlutterResult?

  init(_ callback: @escaping FlutterResult) {
    self.callback = callback
  }

  func success(_ value: Any?) {
    finish(value)
  }

  func failure(_ failure: LightingBridgeFailure) {
    finish(failure.flutterError())
  }

  func failure(code: String, message: String, details: Any? = nil) {
    finish(FlutterError(code: code, message: message, details: details))
  }

  func notImplemented() {
    finish(FlutterMethodNotImplemented)
  }

  private func finish(_ value: Any?) {
    lock.lock()
    let callback = callback
    self.callback = nil
    lock.unlock()
    if Thread.isMainThread {
      callback?(value)
    } else {
      DispatchQueue.main.async { callback?(value) }
    }
  }
}
