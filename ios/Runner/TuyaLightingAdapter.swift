import Foundation
import CoreFoundation
import Security
import CoreBluetooth
import CoreLocation
import NetworkExtension

#if canImport(ThingSmartHomeKit)
import ThingSmartHomeKit
#endif

func makeLightingAdapter() -> LightingNativeAdapter {
  #if canImport(ThingSmartHomeKit) && !targetEnvironment(simulator)
    return TuyaLightingAdapter()
  #else
    return UnavailableLightingAdapter()
  #endif
}

#if canImport(ThingSmartHomeKit) && !targetEnvironment(simulator)
/// The demo account belongs to this installation and is reused from Keychain.
/// Cloud callbacks are serialized on main, matching Flutter channel callbacks.
private final class TuyaLightingAdapter: NSObject, LightingNativeAdapter, ThingSmartActivatorDelegate, ThingSmartDeviceDelegate,
  ThingSmartBLEManagerDelegate, ThingSmartBLEWifiActivatorDelegate {
  private(set) var readiness: LightingReadiness = .configurationMissing
  var onEvent: (([String: Any]) -> Void)?
  private var initialized = false
  // Local opt-in is enabled only after the signed app and profile are verified
  // to contain Apple's restricted multicast entitlement. iOS enforces it.
  private var ezEntitlementConfigured = false
  private var home: ThingSmartHome?
  private var homeManager: ThingSmartHomeManager?
  private var identity: DemoIdentity?
  private var devices: [[String: Any]] = []
  private var observedDevices: [String: ThingSmartDevice] = [:]
  private var powerDPIDs: [String: String] = [:]
  private var reportedPower: [String: Bool] = [:]
  private var reportedDPs: [String: [String: Any]] = [:]
  private var lightProfiles: [String: TuyaLightProfile] = [:]
  private var pendingCommandTokens: [String: UUID] = [:]
  private var commandTimers: [String: DispatchWorkItem] = [:]
  private var removingDeviceIDs: Set<String> = []
  private var removedDeviceIDs: Set<String> = []
  private var setupCallbacks: [(Result<[String: Any], LightingBridgeFailure>) -> Void] = []
  private var activator: ThingSmartActivator?
  private var operationID: String?
  private var pairingTimer: DispatchWorkItem?
  private var pairingToken: String?
  private var tokenExpiry: Date?
  private var acquiringToken = false
  private var tokenRequestID = 0
  private var tokenCompletion: ((Result<Void, LightingBridgeFailure>) -> Void)?
  private var tokenTimeout: DispatchWorkItem?
  private let wifiReader = CurrentWifiReader()
  private let bulbHotspotPrefix = "SmartLife"
  private var discoveringHotspot = false
  private var hotspotRequestID = 0
  private var hotspotCompletion: ((Result<[String: Any], LightingBridgeFailure>) -> Void)?
  private var connectedBulbHotspot: String?
  private var wifiListActivator: ThingSmartActivator?
  private var wifiListCompletion: ((Result<[String: Any], LightingBridgeFailure>) -> Void)?
  private var wifiListTimeout: DispatchWorkItem?
  private var wifiListRequestID = 0
  private var apPlusNetworks: Set<String> = []
  private var securityConfigs: [String: Any]?
  private var securityActivator: ThingSmartActivator?
  private var securityRequestID = 0
  private var securityCompletion: (() -> Void)?
  // Bluetooth nearby scan (spec 013). Advertisement models stay native; Flutter
  // only sees the app-owned ids in nearbyIDsByUUID.
  private var scanRequested = false
  private var listening = false
  private var scanGeneration = 0
  private var nearbyCounter = 0
  private var nearbyModels: [String: ThingBLEAdvModel] = [:]
  private var nearbyIDsByUUID: [String: String] = [:]
  private var nearbyOrder: [String] = []
  private var nearbyProducts: [String: NearbyProduct] = [:]
  private var bleAttemptUUID: String?

  func pairingCapabilities() -> [String: Any] {
    ["ezAvailable": ezEntitlementConfigured,
      "ezReason": ezEntitlementConfigured ? NSNull() : "multicastEntitlementRequired"]
  }

  func initialize() -> [String: Any] {
    if !initialized {
      guard let url = Bundle.main.url(forResource: "TuyaConfig", withExtension: "plist"),
        let data = try? Data(contentsOf: url),
        let config = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
        let key = config["AppKey"] as? String, !key.isEmpty,
        let secret = config["AppSecret"] as? String, !secret.isEmpty,
        !key.hasPrefix("YOUR_"), !secret.hasPrefix("YOUR_"),
        !key.hasPrefix("PASTE_"), !secret.hasPrefix("PASTE_")
      else { return snapshot() }
      ThingSmartSDK.sharedInstance().debugMode = false
      ThingSmartSDK.sharedInstance().start(withAppKey: key, secretKey: secret)
      ezEntitlementConfigured = config["EnableEZ"] as? Bool == true
      initialized = true
      readiness = .sessionRequired
    }
    return snapshot()
  }

  func prepareHome(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void) {
    _ = initialize()
    guard initialized else {
      completion(.failure(failure("configurationMissing", "The local Tuya configuration is missing.")))
      return
    }
    guard operationID == nil, !acquiringToken else {
      completion(.failure(failure("busy", "Finish the current pairing attempt first.")))
      return
    }
    setupCallbacks.append(completion)
    guard setupCallbacks.count == 1 else { return }
    pairingToken = nil
    tokenExpiry = nil
    do {
      identity = try DemoIdentity.loadOrCreate()
    } catch {
      finishSetup(.failure(failure("transportFailure", "The demo account could not be read securely. Unlock the iPhone and retry.")))
      return
    }
    guard let identity else { return }
    // Always authenticate the installation's UID, even if the SDK has another cached session.
    ThingSmartUser.sharedInstance().loginOrRegister(withCountryCode: "66", uid: identity.uid,
      password: identity.password, createHome: false,
      success: { [weak self] _ in self?.onMain { self?.selectHome() } },
      failure: { [weak self] _ in self?.onMain {
        guard let self else { return }
        self.readiness = .sessionRequired
        self.finishSetup(.failure(self.failure("sessionRequired", "The demo account could not sign in. Check the internet connection and retry.")))
      } })
  }

  private func selectHome() {
    let manager = ThingSmartHomeManager()
    homeManager = manager
    manager.getHomeList(success: { [weak self] homes in self?.onMain {
      guard let self else { return }
      guard let homes else {
        self.finishSetup(.failure(self.failure("transportFailure", "The demo home list could not be loaded.")))
        return
      }
      let savedID = self.identity?.homeID
      if let selected = homes.first(where: { $0.homeId == savedID }) ?? homes.first {
        self.loadHome(selected.homeId)
      } else {
        manager.addHome(withName: "JAVIS Demo Home", geoName: "", rooms: [], latitude: 0, longitude: 0,
          success: { [weak self] homeID in self?.onMain { self?.loadHome(homeID) } },
          failure: { [weak self] _ in self?.onMain {
            guard let self else { return }
            self.finishSetup(.failure(self.failure("transportFailure", "The demo home could not be created. Check the internet connection and retry.")))
          } })
      }
    } }, failure: { [weak self] _ in self?.onMain {
      guard let self else { return }
      self.finishSetup(.failure(self.failure("transportFailure", "The demo home could not be loaded. Check the internet connection and retry.")))
    } })
  }

  private func loadHome(_ homeID: Int64) {
    guard homeID > 0, let selected = ThingSmartHome(homeId: homeID) else {
      finishSetup(.failure(failure("sessionRequired", "A usable demo home is required.")))
      return
    }
    do {
      identity?.homeID = homeID
      try identity?.save()
    } catch {
      finishSetup(.failure(failure("transportFailure", "The demo home could not be saved securely. Unlock the iPhone and retry.")))
      return
    }
    home = selected
    selected.getDataWithSuccess({ [weak self] _ in self?.onMain {
      guard let self else { return }
      self.devices = self.deviceSnapshot()
      self.readiness = .ready
      self.finishSetup(.success(self.snapshot()))
    } }, failure: { [weak self] _ in self?.onMain {
      guard let self else { return }
      self.finishSetup(.failure(self.failure("transportFailure", "The demo home details could not be loaded. Check the internet connection and retry.")))
    } })
  }

  func refreshDevices(completion: @escaping (Result<[[String: Any]], LightingBridgeFailure>) -> Void) {
    guard initialized, ThingSmartUser.sharedInstance().isLogin, let home else {
      readiness = initialized ? .sessionRequired : .configurationMissing
      devices = []
      completion(.failure(failure(readiness.rawValue, "Prepare the demo home before loading devices.")))
      return
    }
    home.getDataWithSuccess({ [weak self] _ in self?.onMain {
      guard let self else { return }
      self.devices = self.deviceSnapshot()
      completion(.success(self.devices))
    } }, failure: { [weak self] _ in self?.onMain {
      guard let self else { return }
      completion(.failure(self.failure("transportFailure", "Devices could not be refreshed. Reconnect to the home Wi-Fi and retry.")))
    } })
  }

  private func fetchPairingToken(homeID: Int64, completion: @escaping (Result<Void, LightingBridgeFailure>) -> Void) {
    acquiringToken = true
    pairingToken = nil
    tokenExpiry = nil
    tokenRequestID += 1
    let requestID = tokenRequestID
    tokenCompletion = completion
    let timeout = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.finishTokenRequest(requestID, .failure(self.failure("timeout", "The pairing token request timed out. Check the internet connection and retry.")))
    }
    tokenTimeout = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeout)
    let tokenActivator = ThingSmartActivator()
    tokenActivator.getTokenWithHomeId(homeID, success: { [weak self, tokenActivator] token in
      _ = tokenActivator // Keep the token request owner alive through completion.
      self?.onMain {
        guard let self else { return }
        guard let token, !token.isEmpty else {
          self.finishTokenRequest(requestID, .failure(self.failure("pairingFailed", "A pairing token could not be prepared.")))
          return
        }
        guard self.tokenRequestID == requestID, self.tokenCompletion != nil else { return }
        self.pairingToken = token
        self.tokenExpiry = Date().addingTimeInterval(8 * 60)
        self.finishTokenRequest(requestID, .success(()))
      }
    }, failure: { [weak self, tokenActivator] _ in
      _ = tokenActivator
      self?.onMain {
        guard let self else { return }
        self.finishTokenRequest(requestID, .failure(self.failure("transportFailure", "Connect to the internet and prepare pairing again.")))
      }
    })
  }

  private func finishTokenRequest(_ requestID: Int, _ result: Result<Void, LightingBridgeFailure>) {
    guard tokenRequestID == requestID, let callback = tokenCompletion else { return }
    tokenCompletion = nil
    tokenTimeout?.cancel()
    tokenTimeout = nil
    acquiringToken = false
    callback(result)
  }

  func preparePairing(completion: @escaping (Result<Void, LightingBridgeFailure>) -> Void) {
    guard readiness == .ready, ThingSmartUser.sharedInstance().isLogin,
      let homeID = identity?.homeID, homeID > 0 else {
      completion(.failure(failure("sessionRequired", "Prepare the demo home before pairing.")))
      return
    }
    guard operationID == nil, !acquiringToken, !discoveringHotspot,
      wifiListCompletion == nil, setupCallbacks.isEmpty else {
      completion(.failure(failure("busy", "A pairing attempt is already active.")))
      return
    }
    clearWifiList()
    securityConfigs = nil
    fetchPairingToken(homeID: homeID) { [weak self] outcome in
      switch outcome {
      case .failure(let error): completion(.failure(error))
      case .success:
        // AP+ needs this security configuration; legacy AP remains available
        // if the optional request fails or times out.
        self?.fetchSecurityConfigs { completion(.success(())) }
      }
    }
  }

  private func fetchSecurityConfigs(completion: @escaping () -> Void) {
    securityRequestID += 1
    let requestID = securityRequestID
    let request = ThingSmartActivator()
    securityActivator = request
    securityCompletion = completion
    let finish: ([String: Any]?) -> Void = { [weak self] configs in
      guard let self, self.securityRequestID == requestID,
        self.securityActivator === request else { return }
      self.securityActivator = nil
      self.securityConfigs = configs
      let callback = self.securityCompletion
      self.securityCompletion = nil
      callback?()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 8) { finish(nil) }
    request.getDeviceSecurityConfigs({ [weak self, request] configs in
      _ = request
      self?.onMain { finish(configs as? [String: Any]) }
    }, failure: { [weak self, request] _ in
      _ = request
      self?.onMain { finish(nil) }
    })
  }

  func currentWifi(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void) {
    guard readiness == .ready else {
      completion(.failure(failure("sessionRequired", "Prepare the demo home before finding a device.")))
      return
    }
    wifiReader.read(requestLocationPermission: true) { [weak self] ssid in
      self?.onMain {
        completion(.success(["ssid": ssid as Any? ?? NSNull()]))
      }
    }
  }

  func discoverBulbHotspot(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void) {
    guard readiness == .ready, ThingSmartUser.sharedInstance().isLogin else {
      completion(.failure(failure("sessionRequired", "Prepare the demo home before finding a device.")))
      return
    }
    guard !discoveringHotspot, wifiListCompletion == nil,
      operationID == nil, !acquiringToken, setupCallbacks.isEmpty else {
      completion(.failure(failure("busy", "Another device setup step is active.")))
      return
    }
    guard pairingToken != nil, let expiry = tokenExpiry, expiry > Date() else {
      completion(.failure(failure("timeout", "Prepare pairing while the iPhone is online, then try again.")))
      return
    }
    discoveringHotspot = true
    hotspotRequestID += 1
    let requestID = hotspotRequestID
    hotspotCompletion = completion
    connectedBulbHotspot = nil
    let config = NEHotspotConfiguration(ssidPrefix: bulbHotspotPrefix)
    config.joinOnce = true
    NEHotspotConfigurationManager.shared.apply(config) { [weak self] error in
      self?.onMain {
        guard let self, self.discoveringHotspot,
          self.hotspotRequestID == requestID else { return }
        if let error = error as NSError?,
          error.domain == NEHotspotConfigurationErrorDomain,
          error.code == NEHotspotConfigurationError.userDenied.rawValue {
          self.discoveringHotspot = false
          self.hotspotCompletion = nil
          completion(.failure(self.failure("permissionDenied", "Allow iOS to join the bulb hotspot, or use manual AP setup.")))
          return
        }
        // Applying a configuration is not evidence that iOS joined the hotspot.
        self.verifyJoinedBulbHotspot(attemptsRemaining: 8, requestID: requestID, completion: completion)
      }
    }
  }

  private func verifyJoinedBulbHotspot(
    attemptsRemaining: Int,
    requestID: Int,
    completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void
  ) {
    wifiReader.read(requestLocationPermission: false) { [weak self] ssid in
      self?.onMain {
        guard let self, self.discoveringHotspot,
          self.hotspotRequestID == requestID else { return }
        if let ssid, ssid.hasPrefix(self.bulbHotspotPrefix) {
          self.connectedBulbHotspot = ssid
          self.discoveringHotspot = false
          self.hotspotCompletion = nil
          completion(.success(["ssid": ssid, "name": "SmartLife device hotspot"]))
        } else if attemptsRemaining > 1 {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.verifyJoinedBulbHotspot(attemptsRemaining: attemptsRemaining - 1,
              requestID: requestID, completion: completion)
          }
        } else {
          self.discoveringHotspot = false
          self.hotspotCompletion = nil
          completion(.failure(self.failure("noDevices", "No matching bulb hotspot was joined. Reset the bulb to slow-blink AP mode or use manual setup.")))
        }
      }
    }
  }

  func listBulbWifi(completion: @escaping (Result<[String: Any], LightingBridgeFailure>) -> Void) {
    guard readiness == .ready, connectedBulbHotspot != nil, !discoveringHotspot,
      wifiListActivator == nil, operationID == nil else {
      completion(.failure(failure("busy", "Connect to a device hotspot before asking it for Wi-Fi networks.")))
      return
    }
    wifiReader.read(requestLocationPermission: false) { [weak self] ssid in
      self?.onMain {
        guard let self else { return }
        guard ssid == self.connectedBulbHotspot else {
          self.connectedBulbHotspot = nil
          completion(.failure(self.failure("noDevices", "The iPhone is no longer on the bulb hotspot.")))
          return
        }
        let activator = ThingSmartActivator()
        self.wifiListActivator = activator
        self.wifiListRequestID += 1
        let requestID = self.wifiListRequestID
        self.wifiListCompletion = completion
        activator.delegate = self
        let timeout = DispatchWorkItem { [weak self, weak activator] in
          guard let self, self.wifiListActivator === activator,
            self.wifiListRequestID == requestID else { return }
          self.finishWifiList(.failure(self.failure("timeout", "The device did not return Wi-Fi networks. Use manual AP setup.")))
        }
        self.wifiListTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 22, execute: timeout)
        // AP+ first establishes a Tuya device channel, then returns networks
        // through didDiscoverWifiList. A raw Wi-Fi hotspot is not sufficient.
        activator.connectDeviceAndQueryWifiList(withTimeout: 18)
      }
    }
  }

  func activator(_ activator: ThingSmartActivator, didDiscoverWifiList wifiList: [Any]?, error: Error?) {
    onMain { [weak self] in
      guard let self, self.wifiListActivator === activator,
        self.wifiListCompletion != nil else { return }
      guard error == nil else {
        self.finishWifiList(.failure(self.failure("noDevices", "This device cannot provide a Wi-Fi list. Use manual AP setup.")))
        return
      }
      var names = Set<String>()
      for item in wifiList ?? [] {
        let name: String?
        if let info = item as? ThingSmartPairingWiFiInfo {
          name = info.ssid
        } else if let data = item as? [String: Any] {
          name = data["ssid"] as? String
        } else {
          name = nil
        }
        // SSIDs are byte-exact identifiers. Do not trim valid spaces.
        if let name, !name.isEmpty, name.utf8.count <= 32 { names.insert(name) }
      }
      guard !names.isEmpty else {
        self.finishWifiList(.failure(self.failure("noDevices", "No supported Wi-Fi networks were returned. Use manual AP setup.")))
        return
      }
      self.apPlusNetworks = names
      self.wifiListTimeout?.cancel()
      self.wifiListTimeout = nil
      let callback = self.wifiListCompletion
      self.wifiListCompletion = nil
      callback?(.success(["networks": names.sorted().map { ["ssid": $0] }]))
    }
  }

  func deviceStateError(_ error: Error) {
    onMain { [weak self] in
      guard let self, self.wifiListCompletion != nil else { return }
      self.finishWifiList(.failure(self.failure("noDevices", "This device does not support network selection. Use manual AP setup.")))
    }
  }

  private func finishWifiList(_ result: Result<[String: Any], LightingBridgeFailure>) {
    let callback = wifiListCompletion
    clearWifiList()
    callback?(result)
  }

  private func clearWifiList() {
    wifiListRequestID += 1
    wifiListTimeout?.cancel()
    wifiListTimeout = nil
    wifiListCompletion = nil
    apPlusNetworks = []
    let previous = wifiListActivator
    wifiListActivator = nil
    previous?.delegate = nil
    previous?.stopConfigWiFi()
  }

  func cancelSetup() {
    hotspotRequestID += 1
    let hotspotCallback = hotspotCompletion
    discoveringHotspot = false
    hotspotCompletion = nil
    hotspotCallback?(.failure(failure("cancelled", "Device search was cancelled.")))
    let wifiCallback = wifiListCompletion
    clearWifiList()
    wifiCallback?(.failure(failure("cancelled", "Wi-Fi network search was cancelled.")))
    tokenRequestID += 1
    let pendingToken = tokenCompletion
    tokenCompletion = nil
    tokenTimeout?.cancel()
    tokenTimeout = nil
    acquiringToken = false
    pendingToken?(.failure(failure("cancelled", "Pairing preparation was cancelled.")))
    securityRequestID += 1
    securityActivator = nil
    let pendingSecurity = securityCompletion
    securityCompletion = nil
    pendingSecurity?()
    connectedBulbHotspot = nil
    pairingToken = nil
    tokenExpiry = nil
    securityConfigs = nil
  }

  func startPairing(operationID: String, ssid: String, password: String, mode: String, deviceID: String?) throws {
    guard readiness == .ready, ThingSmartUser.sharedInstance().isLogin, home != nil else {
      throw failure("sessionRequired", "Prepare the demo home before pairing.")
    }
    guard self.operationID == nil, !acquiringToken, !discoveringHotspot,
      wifiListCompletion == nil, setupCallbacks.isEmpty else {
      throw failure("busy", "A pairing attempt is already active.")
    }
    guard mode == "ap" || mode == "ez" || mode == "ble" else {
      throw failure("invalidArguments", "Choose a supported pairing mode.")
    }
    if mode == "ble" {
      try startBLEPairing(operationID: operationID, deviceID: deviceID, ssid: ssid, password: password)
      return
    }
    if mode == "ez" {
      guard pairingCapabilities()["ezAvailable"] as? Bool == true else {
        throw failure("multicastEntitlementRequired", "EZ pairing needs Apple's approved multicast entitlement for this signed app.")
      }
      guard connectedBulbHotspot == nil, wifiListActivator == nil else {
        throw failure("noDevices", "Reconnect the iPhone to home Wi-Fi before fast-blink pairing.")
      }
      let currentSSID = ThingSmartActivator.currentWifiSSID()
      // iOS may hide the current SSID when optional location access is denied.
      // In that case honor the network the user explicitly entered; if iOS
      // does expose the SSID, reject a known mismatch or a device hotspot.
      guard currentSSID.isEmpty ||
        (currentSSID == ssid && !currentSSID.hasPrefix(bulbHotspotPrefix)) else {
        throw failure("noDevices", "Keep the iPhone on the selected home Wi-Fi while pairing in fast-blink mode.")
      }
    }
    guard let token = pairingToken, let expiry = tokenExpiry, expiry > Date() else {
      throw failure("timeout", "Connect to the internet and prepare pairing again.")
    }
    let useAPPlus = mode == "ap" && apPlusNetworks.contains(ssid)
    if connectedBulbHotspot != nil && !useAPPlus {
      throw failure("noDevices", "Use manual AP setup when this device cannot provide a Wi-Fi list.")
    }
    if useAPPlus {
      guard let connectedBulbHotspot,
        ThingSmartActivator.currentWifiSSID() == connectedBulbHotspot,
        wifiListActivator != nil else {
        throw failure("noDevices", "Reconnect to the bulb hotspot before pairing.")
      }
    }
    self.operationID = operationID
    pairingToken = nil
    tokenExpiry = nil
    let attempt = useAPPlus ? wifiListActivator! : ThingSmartActivator()
    wifiListActivator = nil
    apPlusNetworks = []
    connectedBulbHotspot = nil
    activator = attempt
    attempt.delegate = self
    let timer = DispatchWorkItem { [weak self, weak attempt] in
      guard let self, self.operationID == operationID, self.activator === attempt else { return }
      self.finishPairing(status: "failed", errorCode: "timeout")
    }
    pairingTimer = timer
    DispatchQueue.main.asyncAfter(deadline: .now() + 105, execute: timer)
    if mode == "ez" {
      attempt.startConfigWiFi(.EZ, ssid: ssid, password: password, token: token, timeout: 100)
    } else if useAPPlus {
      if let securityConfigs {
        attempt.resumeAPPlus(withSSID: ssid, password: password, token: token,
          timeout: 100, reg: securityConfigs)
      } else {
        attempt.resumeAPPlus(withSSID: ssid, password: password, token: token,
          timeout: 100)
      }
    } else {
      attempt.startConfigWiFi(.AP, ssid: ssid, password: password, token: token, timeout: 100)
    }
  }

  func cancelPairing(operationID: String) {
    guard self.operationID == operationID else { return }
    clearPairing()
  }

  func sendCommand(deviceID: String, command: [String: Any], completion: @escaping (Result<Void, LightingBridgeFailure>) -> Void) {
    guard !removingDeviceIDs.contains(deviceID) else {
      completion(.failure(failure("busy", "This light is being removed.")))
      return
    }
    guard readiness == .ready, ThingSmartUser.sharedInstance().isLogin,
      let model = home?.deviceList?.first(where: { $0.devId == deviceID }),
      let device = observedDevices[deviceID], device.deviceModel.isOnline else {
      completion(.failure(failure("unavailable", "The light is offline or no longer belongs to this home.")))
      return
    }
    guard let dataPoints = dataPoints(for: command, model: model, device: device), !dataPoints.isEmpty else {
      completion(.failure(failure("unsupportedCommand", "This light does not support that command.")))
      return
    }
    guard pendingCommandTokens[deviceID] == nil else {
      completion(.failure(failure("busy", "A light command is already in progress.")))
      return
    }
    let token = UUID()
    pendingCommandTokens[deviceID] = token
    let timeout = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.finishCommand(deviceID: deviceID, token: token,
        outcome: .failure(self.failure("timeout", "The light did not acknowledge the command.")),
        completion: completion)
    }
    commandTimers[deviceID] = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: timeout)
    device.publishDps(dataPoints, success: { [weak self] in
      self?.onMain {
        self?.finishCommand(deviceID: deviceID, token: token, outcome: .success(()), completion: completion)
      }
    }, failure: { [weak self] _ in
      self?.onMain {
        guard let self else { return }
        self.finishCommand(deviceID: deviceID, token: token,
          outcome: .failure(self.failure("transportFailure", "The light did not accept the command. Check its connection and retry.")),
          completion: completion)
      }
    })
  }

  func removeDevice(deviceID: String, completion: @escaping (Result<[[String: Any]], LightingBridgeFailure>) -> Void) {
    guard readiness == .ready, ThingSmartUser.sharedInstance().isLogin,
      home?.deviceList?.contains(where: { $0.devId == deviceID }) == true,
      let device = observedDevices[deviceID] else {
      completion(.failure(failure("unavailable", "This light no longer belongs to the current home.")))
      return
    }
    guard operationID == nil, pendingCommandTokens[deviceID] == nil,
      removingDeviceIDs.insert(deviceID).inserted else {
      completion(.failure(failure("busy", "Finish the current light operation first.")))
      return
    }
    device.remove({ [weak self] in
      self?.onMain {
        guard let self else { return }
        self.removingDeviceIDs.remove(deviceID)
        self.removedDeviceIDs.insert(deviceID)
        self.observedDevices[deviceID]?.delegate = nil
        self.observedDevices.removeValue(forKey: deviceID)
        self.reportedPower.removeValue(forKey: deviceID)
        self.reportedDPs.removeValue(forKey: deviceID)
        self.lightProfiles.removeValue(forKey: deviceID)
        self.powerDPIDs.removeValue(forKey: deviceID)
        self.emitDeviceSnapshot()
        completion(.success(self.devices))
      }
    }, failure: { [weak self] _ in
      self?.onMain {
        guard let self else { return }
        self.removingDeviceIDs.remove(deviceID)
        completion(.failure(self.failure("transportFailure", "The light could not be removed. Check your connection and retry.")))
      }
    })
  }

  private func finishCommand(deviceID: String, token: UUID,
    outcome: Result<Void, LightingBridgeFailure>,
    completion: @escaping (Result<Void, LightingBridgeFailure>) -> Void) {
    guard pendingCommandTokens[deviceID] == token else { return }
    pendingCommandTokens.removeValue(forKey: deviceID)
    commandTimers.removeValue(forKey: deviceID)?.cancel()
    completion(outcome)
  }

  func device(_ device: ThingSmartDevice, dpsUpdate dps: [AnyHashable: Any]) {
    onMain { [weak self] in
      guard let self, self.observedDevices[device.devId] === device else { return }
      if let dpID = self.powerDPIDs[device.devId],
        let power = self.reportedBoolean(dps[dpID]) {
        self.reportedPower[device.devId] = power
      }
      self.reportedDPs[device.devId, default: [:]].merge(self.stringKeyed(dps)) { _, new in new }
      self.emitDeviceSnapshot()
    }
  }

  func deviceOnlineUpdate(_ device: ThingSmartDevice) {
    onMain { [weak self] in
      guard let self, self.observedDevices[device.devId] === device else { return }
      self.emitDeviceSnapshot()
    }
  }

  func deviceInfoUpdate(_ device: ThingSmartDevice) {
    onMain { [weak self] in
      guard let self, self.observedDevices[device.devId] === device else { return }
      self.emitDeviceSnapshot()
    }
  }

  private func emitDeviceSnapshot() {
    guard readiness == .ready else { return }
    devices = deviceSnapshot()
    onEvent?(["type": "devices", "devices": devices])
  }

  func activator(_ activator: ThingSmartActivator, didReceiveDevice deviceModel: ThingSmartDeviceModel?, error: Error?) {
    onMain { [weak self] in
      guard let self, self.activator === activator, self.operationID != nil else { return }
      if error != nil {
        self.finishPairing(status: "failed", errorCode: "pairingFailed")
      } else if let id = deviceModel?.devId, !id.isEmpty {
        self.finishPairing(status: "success", deviceID: id)
      }
    }
  }

  func activator(_ activator: ThingSmartActivator, didReceiveDevice deviceModel: ThingSmartDeviceModel?, step: ThingActivatorStep, error: Error?) {
    onMain { [weak self] in
      guard let self, self.activator === activator, let id = self.operationID else { return }
      if step == .timeOut {
        self.finishPairing(status: "failed", errorCode: "timeout")
      } else if error != nil {
        self.finishPairing(status: "failed", errorCode: "pairingFailed")
      } else {
        self.onEvent?(["type": "pairing", "operationId": id, "status": "activating"])
      }
    }
  }

  private func finishPairing(status: String, deviceID: String? = nil, errorCode: String? = nil) {
    guard let id = operationID else { return }
    clearPairing()
    if status == "success", let deviceID { removedDeviceIDs.remove(deviceID) }
    var event: [String: Any] = ["type": "pairing", "operationId": id, "status": status]
    event["deviceId"] = deviceID
    event["errorCode"] = errorCode
    onEvent?(event)
  }

  private func clearPairing() {
    operationID = nil // Invalidate before stopping: SDK may call back synchronously.
    pairingTimer?.cancel()
    pairingTimer = nil
    let previous = activator
    activator = nil
    previous?.delegate = nil
    previous?.stopConfigWiFi()
    securityConfigs = nil
    if bleAttemptUUID != nil {
      bleAttemptUUID = nil
      let bleActivator = ThingSmartBLEWifiActivator.sharedInstance()
      bleActivator.bleWifiDelegate = nil
      bleActivator.stopDiscover()
    }
  }

  private func deviceSnapshot() -> [[String: Any]] {
    let models = home?.deviceList ?? []
    let currentIDs = Set(models.compactMap { $0.devId })
    for id in Array(observedDevices.keys) where !currentIDs.contains(id) {
      observedDevices[id]?.delegate = nil
      observedDevices.removeValue(forKey: id)
      reportedPower.removeValue(forKey: id)
      reportedDPs.removeValue(forKey: id)
    }
    powerDPIDs.removeAll()
    lightProfiles.removeAll()
    return models.compactMap { model in
      guard let id = model.devId, !id.isEmpty,
        !removedDeviceIDs.contains(id) else { return nil }
      if observedDevices[id] == nil, let device = ThingSmartDevice(deviceId: id) {
        device.delegate = self
        observedDevices[id] = device
      }
      let liveModel = observedDevices[id]?.deviceModel
      let dpID = verifiedPowerDPID(homeModel: model, liveModel: liveModel)
      let reported = dpID.flatMap { id in
        reportedPower[model.devId] ?? reportedBoolean(liveModel?.dps?[id]) ?? reportedBoolean(model.dps?[id])
      }
      if let dpID, reported != nil { powerDPIDs[id] = dpID }
      let dps = knownDPs(id, homeModel: model, liveModel: liveModel)
      let profile = lightProfile(homeModel: model, liveModel: liveModel, reported: dps)
      lightProfiles[id] = profile
      var capabilities = profile.capabilities
      capabilities["power"] = dpID != nil && reported != nil
      var snapshot: [String: Any] = ["id": id, "name": liveModel?.name ?? model.name ?? "Smart bulb",
        "room": "", "online": liveModel?.isOnline ?? model.isOnline, "isOn": reported ?? false,
        "capabilities": capabilities]
      snapshot.merge(profile.state(reported: dps)) { _, new in new }
      return snapshot
    }
  }

  private func dataPoints(for command: [String: Any], model: ThingSmartDeviceModel,
    device: ThingSmartDevice) -> [String: Any]? {
    let deviceID = device.devId ?? ""
    let dps = knownDPs(deviceID, homeModel: model, liveModel: device.deviceModel)
    guard let profile = lightProfiles[deviceID],
      var result = profile.dataPoints(for: command, reported: dps) else { return nil }
    if let isOn = command["isOn"] {
      guard let desired = reportedBoolean(isOn), let dpID = powerDPIDs[deviceID],
        dpID == verifiedPowerDPID(homeModel: model, liveModel: device.deviceModel),
        reportedBoolean(dps[dpID]) != nil else { return nil }
      result[dpID] = desired
    }
    return result
  }

  /// Everything the bulb has told us, newest last. Device events win.
  private func knownDPs(_ id: String, homeModel: ThingSmartDeviceModel,
    liveModel: ThingSmartDeviceModel?) -> [String: Any] {
    var known = stringKeyed(homeModel.dps ?? [:])
    known.merge(stringKeyed(liveModel?.dps ?? [:])) { _, new in new }
    known.merge(reportedDPs[id] ?? [:]) { _, new in new }
    return known
  }

  private func stringKeyed(_ dps: [AnyHashable: Any]) -> [String: Any] {
    var keyed: [String: Any] = [:]
    for (key, value) in dps { keyed[String(describing: key.base)] = value }
    return keyed
  }

  private func lightProfile(homeModel: ThingSmartDeviceModel, liveModel: ThingSmartDeviceModel?,
    reported: [String: Any]) -> TuyaLightProfile {
    let schema = liveModel?.schemaArray ?? homeModel.schemaArray ?? []
    let items = schema.map { item in
      LightSchemaItem(dpID: item.dpId, code: item.code, mode: item.mode,
        type: item.property?.type ?? "", min: Int(item.property?.min ?? 0),
        max: Int(item.property?.max ?? 0),
        options: item.property?.range?.compactMap { $0 as? String } ?? [])
    }
    return TuyaLightProfile(items: items, reported: reported)
  }

  private func verifiedPowerDPID(homeModel: ThingSmartDeviceModel,
    liveModel: ThingSmartDeviceModel?) -> String? {
    var ids = Set<String>()
    for schema in (homeModel.schemaArray ?? []) + (liveModel?.schemaArray ?? []) {
      if schema.code == "switch_led", schema.mode == "rw",
        schema.property?.type == "bool", !schema.dpId.isEmpty {
        ids.insert(schema.dpId)
      }
    }
    return ids.count == 1 ? ids.first : nil
  }

  private func reportedBoolean(_ value: Any?) -> Bool? {
    guard let number = value as? NSNumber,
      CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
    return number.boolValue
  }

  private func snapshot() -> [String: Any] {
    ["readiness": readiness.rawValue, "devices": readiness == .ready ? devices : [],
      "canRestoreHome": DemoIdentity.hasStoredIdentity()]
  }

  private func finishSetup(_ result: Result<[String: Any], LightingBridgeFailure>) {
    let callbacks = setupCallbacks
    setupCallbacks = []
    callbacks.forEach { $0(result) }
  }

  private func failure(_ code: String, _ message: String) -> LightingBridgeFailure {
    LightingBridgeFailure(code: code, message: message, details: nil)
  }

  private func onMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
  }
}

/// Bluetooth nearby scan and Wi-Fi + BLE (dual-mode) activation, spec 013.
extension TuyaLightingAdapter {
  /// Tuya dual-mode Wi-Fi types; other BLE types cannot take home Wi-Fi.
  private static let wifiComboTypes: Set<UInt> = [
    ThingSmartBLETypeBLEWifi.rawValue, ThingSmartBLETypeBLEWifiSecurity.rawValue,
    ThingSmartBLETypeBLEWifiPlugPlay.rawValue, ThingSmartBLETypeBLEWifiPriorBLE.rawValue,
  ]

  func startDeviceScan() throws -> [String: Any] {
    guard readiness == .ready, ThingSmartUser.sharedInstance().isLogin, home != nil else {
      throw failure("sessionRequired", "Prepare the demo home before finding a device.")
    }
    guard operationID == nil else {
      throw failure("busy", "Finish the current pairing attempt first.")
    }
    let manager = ThingSmartBLEManager.sharedInstance()
    manager.delegate = self
    if listening { manager.stopListening(true) }
    listening = false
    scanRequested = true
    scanGeneration += 1
    let generation = scanGeneration
    nearbyModels = [:]
    nearbyIDsByUUID = [:]
    nearbyOrder = []
    nearbyProducts = [:]
    emitNearby()
    if manager.isPoweredOn { startListeningIfNeeded() }
    // The first state update can arrive after this reply, or never if the
    // central was created earlier; re-read it once so "off" is not missed.
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      guard let self, self.scanRequested, self.scanGeneration == generation else { return }
      self.emitBluetooth(self.bluetoothState())
      if ThingSmartBLEManager.sharedInstance().isPoweredOn { self.startListeningIfNeeded() }
    }
    let state = bluetoothState()
    return ["bluetooth": state == "off" ? "unknown" : state]
  }

  func stopDeviceScan() {
    scanRequested = false
    scanGeneration += 1
    if listening { ThingSmartBLEManager.sharedInstance().stopListening(true) }
    listening = false
    nearbyModels = [:]
    nearbyIDsByUUID = [:]
    nearbyOrder = []
    nearbyProducts = [:]
  }

  private func startBLEPairing(operationID: String, deviceID: String?, ssid: String, password: String) throws {
    guard let deviceID, let model = nearbyModels[deviceID], let uuid = model.uuid, !uuid.isEmpty,
      let homeID = identity?.homeID, homeID > 0 else {
      throw failure("deviceNotReady", "This light is no longer nearby. Search again.")
    }
    guard ThingSmartBLEManager.sharedInstance().isPoweredOn else {
      throw failure("bluetoothOff", "Turn on Bluetooth to connect this light.")
    }
    // Scanning is paused while the SDK talks to this one device.
    if listening { ThingSmartBLEManager.sharedInstance().stopListening(false) }
    listening = false
    scanRequested = false
    scanGeneration += 1
    self.operationID = operationID
    bleAttemptUUID = uuid
    let activator = ThingSmartBLEWifiActivator.sharedInstance()
    activator.bleWifiDelegate = self
    let timer = DispatchWorkItem { [weak self] in
      guard let self, self.operationID == operationID, self.bleAttemptUUID == uuid else { return }
      self.finishPairing(status: "failed", errorCode: "timeout")
    }
    pairingTimer = timer
    DispatchQueue.main.asyncAfter(deadline: .now() + 105, execute: timer)
    // Success here means only that the Wi-Fi details reached the device; the
    // provider result arrives in didReceiveBLEWifiConfigDevice.
    activator.startConfigBLEWifiDevice(withUUID: uuid, homeId: homeID, productId: model.productId ?? "",
      ssid: ssid, password: password, timeout: 100,
      success: { [weak self] in self?.onMain {
        guard let self, self.operationID == operationID, self.bleAttemptUUID == uuid else { return }
        self.onEvent?(["type": "pairing", "operationId": operationID, "status": "activating"])
      } },
      failure: { [weak self] in self?.onMain {
        guard let self, self.operationID == operationID, self.bleAttemptUUID == uuid else { return }
        self.finishPairing(status: "failed", errorCode: "pairingFailed")
      } })
  }

  func bleWifiActivator(_ activator: ThingSmartBLEWifiActivator,
    didReceiveBLEWifiConfigDevice deviceModel: ThingSmartDeviceModel?, error: Error?) {
    onMain { [weak self] in
      guard let self, self.operationID != nil, let uuid = self.bleAttemptUUID else { return }
      if let reported = deviceModel?.uuid, !reported.isEmpty, reported != uuid { return }
      if error != nil {
        self.finishPairing(status: "failed", errorCode: "pairingFailed")
      } else if let id = deviceModel?.devId, !id.isEmpty {
        self.finishPairing(status: "success", deviceID: id)
      }
    }
  }

  func bleWifiActivator(_ activator: ThingSmartBLEWifiActivator, notConfigStateWithError error: Error) {
    onMain { [weak self] in
      guard let self, self.operationID != nil, self.bleAttemptUUID != nil else { return }
      self.finishPairing(status: "failed", errorCode: "deviceNotReady")
    }
  }

  func bluetoothDidUpdateState(_ isPoweredOn: Bool) {
    onMain { [weak self] in
      guard let self, self.scanRequested else { return }
      if isPoweredOn {
        self.startListeningIfNeeded()
      } else {
        self.listening = false
      }
      self.emitBluetooth(self.bluetoothState())
    }
  }

  func didDiscoveryDevice(withDeviceInfo deviceInfo: ThingBLEAdvModel) {
    onMain { [weak self] in
      guard let self, self.scanRequested, !deviceInfo.isActive,
        Self.wifiComboTypes.contains(deviceInfo.bleType.rawValue),
        let uuid = deviceInfo.uuid, !uuid.isEmpty else { return }
      let id: String
      if let existing = self.nearbyIDsByUUID[uuid] {
        id = existing
      } else {
        self.nearbyCounter += 1
        id = "nearby-\(self.nearbyCounter)"
        self.nearbyIDsByUUID[uuid] = id
        self.nearbyOrder.append(id)
        self.queryNearbyProduct(id: id, uuid: uuid, productId: deviceInfo.productId)
      }
      self.nearbyModels[id] = deviceInfo
      self.emitNearby()
    }
  }

  private func startListeningIfNeeded() {
    guard scanRequested, !listening else { return }
    listening = true
    ThingSmartBLEManager.sharedInstance().startListening(true)
  }

  private func bluetoothState() -> String {
    switch CBManager.authorization {
    case .denied, .restricted: return "unauthorized"
    default: return ThingSmartBLEManager.sharedInstance().isPoweredOn ? "on" : "off"
    }
  }

  private func emitBluetooth(_ state: String) {
    onEvent?(["type": "bluetooth", "state": state])
  }

  /// Fetches the name and picture shown on the radar, once per device. A failed
  /// query is not an error: the device stays usable with the generic label.
  private func queryNearbyProduct(id: String, uuid: String, productId: String?) {
    guard let productId, !productId.isEmpty else { return }
    ThingSmartBLEManager.sharedInstance().queryDeviceInfo(
      withUUID: uuid, productId: productId,
      success: { [weak self] info in
        self?.onMain { [weak self] in
          guard let self, self.nearbyIDsByUUID[uuid] == id else { return }
          self.nearbyProducts[id] = NearbyProduct(info)
          self.emitNearby()
        }
      },
      failure: { _ in })
  }

  private func emitNearby() {
    let devices = nearbyOrder.map { id -> [String: String] in
      var device = ["id": id]
      device["name"] = nearbyProducts[id]?.name
      device["iconUrl"] = nearbyProducts[id]?.iconUrl
      return device
    }
    onEvent?(["type": "nearby", "devices": devices])
  }
}

/// What Tuya says about a product before it is activated. The SDK's dictionary
/// has no documented keys (spec 018), so either field can be missing.
private struct NearbyProduct {
  let name: String?
  let iconUrl: String?

  init(_ info: [AnyHashable: Any]?) {
    name = info?["name"] as? String
    iconUrl = info?["icon"] as? String
  }
}

/// iOS exposes the current network only with the Wi-Fi information capability
/// and a qualifying authorization. We ask for location solely to prefill the
/// home SSID, never to collect coordinates. Hotspots configured by this app
/// can be read without location authorization.
private final class CurrentWifiReader: NSObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var waitingForAuthorization: [((String?) -> Void)] = []

  override init() {
    super.init()
    locationManager.delegate = self
  }

  func read(requestLocationPermission: Bool, completion: @escaping (String?) -> Void) {
    if requestLocationPermission {
      switch locationManager.authorizationStatus {
      case .notDetermined:
        waitingForAuthorization.append(completion)
        locationManager.requestWhenInUseAuthorization()
        return
      case .denied, .restricted:
        completion(nil)
        return
      default:
        break
      }
    }
    fetchCurrent(completion: completion)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard manager.authorizationStatus != .notDetermined,
      !waitingForAuthorization.isEmpty else { return }
    let callbacks = waitingForAuthorization
    waitingForAuthorization = []
    if manager.authorizationStatus == .authorizedWhenInUse ||
      manager.authorizationStatus == .authorizedAlways {
      fetchCurrent { ssid in callbacks.forEach { $0(ssid) } }
    } else {
      callbacks.forEach { $0(nil) }
    }
  }

  private func fetchCurrent(completion: @escaping (String?) -> Void) {
    NEHotspotNetwork.fetchCurrent { network in
      let ssid = network?.ssid
      completion(ssid?.isEmpty == false ? ssid : nil)
    }
  }
}

private struct DemoIdentity: Codable {
  let uid: String
  let password: String
  var homeID: Int64?
  private static let service = "com.javis.home.tuya-demo"
  private static let account = "installation"

  static func hasStoredIdentity() -> Bool {
    var query = keychainQuery
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
  }

  static func loadOrCreate() throws -> DemoIdentity {
    var query = keychainQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess, let data = item as? Data {
      let identity = try JSONDecoder().decode(DemoIdentity.self, from: data)
      guard !identity.uid.isEmpty, !identity.password.isEmpty else { throw IdentityError.invalid }
      return identity
    }
    guard status == errSecItemNotFound else { throw IdentityError.keychain }
    let identity = DemoIdentity(uid: "javis-" + UUID().uuidString.lowercased(),
      password: "Ja1" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16))
    var attributes = keychainQuery
    attributes[kSecValueData as String] = try JSONEncoder().encode(identity)
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    guard SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess else { throw IdentityError.keychain }
    return identity
  }

  func save() throws {
    let update = [kSecValueData as String: try JSONEncoder().encode(self)]
    guard SecItemUpdate(Self.keychainQuery as CFDictionary, update as CFDictionary) == errSecSuccess else {
      throw IdentityError.keychain
    }
  }

  private static var keychainQuery: [String: Any] {
    [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
      kSecAttrAccount as String: account, kSecAttrSynchronizable as String: false]
  }

  private enum IdentityError: Error { case keychain, invalid }
}
#endif
