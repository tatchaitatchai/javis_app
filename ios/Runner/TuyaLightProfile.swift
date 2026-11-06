import Foundation

/// One schema entry, free of SDK types.
struct LightSchemaItem {
  let dpID: String
  let code: String
  let mode: String
  let type: String
  let min: Int
  let max: Int
  let options: [String]
}

/// What one bulb can do, read from its own schema and reported state, and how
/// app values map to its data points. Nothing here assumes a bulb model.
struct TuyaLightProfile {
  struct ValueDP {
    let id: String
    let min: Int
    let max: Int
  }

  struct ColorValue: Equatable {
    let hue: Int
    let saturation: Int
    let value: Int

    /// The 12-digit `hhhhssssvvvv` layout Tuya documents for lighting products.
    init?(hex: String) {
      let digits = Array(hex)
      guard digits.count == 12 else { return nil }
      func part(_ start: Int) -> Int? { Int(String(digits[start..<start + 4]), radix: 16) }
      guard let hue = part(0), let saturation = part(4), let value = part(8),
        hue <= 360, saturation <= 1000, value <= 1000 else { return nil }
      self.init(hue: hue, saturation: saturation, value: value)
    }

    init(hue: Int, saturation: Int, value: Int) {
      self.hue = hue
      self.saturation = saturation
      self.value = value
    }

    var hex: String { String(format: "%04x%04x%04x", hue, saturation, value) }
  }

  /// `temp_value` has no unit, so the app's Kelvin scale maps onto it nominally.
  static let nominalWarmKelvin = 2700
  static let nominalCoolKelvin = 6500
  private static let whiteMode = "white"
  private static let colorMode = "colour"
  private static let minimumColorValue = 10
  private static let colorScale = 1000

  let brightness: ValueDP?
  let temperature: ValueDP?
  let modeDP: String?
  let colorDP: String?

  init(items: [LightSchemaItem], reported: [String: Any]) {
    func writable(_ codes: [String], type: String) -> LightSchemaItem? {
      for code in codes {
        if let item = items.first(where: { $0.code == code && $0.mode == "rw" && $0.type == type }) {
          return item
        }
      }
      return nil
    }
    func range(_ codes: [String]) -> ValueDP? {
      guard let item = writable(codes, type: "value"), item.min >= 0, item.max > item.min else {
        return nil
      }
      return ValueDP(id: item.dpID, min: item.min, max: item.max)
    }
    brightness = range(["bright_value_v2", "bright_value"])
    temperature = range(["temp_value_v2", "temp_value"])
    let mode = writable(["work_mode"], type: "enum")
    let modes = mode?.options ?? []
    modeDP = modes.contains(Self.whiteMode) && modes.contains(Self.colorMode) ? mode?.dpID : nil
    let color = writable(["colour_data_v2", "colour_data"], type: "string")
    let reportedColor = color.flatMap { reported[$0.dpID] as? String }
    colorDP = modeDP != nil && reportedColor.flatMap(ColorValue.init(hex:)) != nil ? color?.dpID : nil
  }

  var capabilities: [String: Any] {
    var result: [String: Any] = [
      "brightness": brightness != nil,
      "temperature": temperature != nil,
      "color": colorDP != nil,
    ]
    if temperature != nil {
      result["minTemperature"] = Self.nominalWarmKelvin
      result["maxTemperature"] = Self.nominalCoolKelvin
      result["nominalTemperature"] = true
    }
    return result
  }

  /// The state to show, from what the bulb last reported.
  func state(reported: [String: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    if let brightness, let value = number(reported[brightness.id]) {
      result["brightness"] = Double(value) / Double(brightness.max)
    }
    if let temperature, let value = number(reported[temperature.id]) {
      result["temperature"] = kelvin(fromDP: value, temperature)
    }
    if let color = activeColor(reported: reported) {
      result["brightness"] = Double(color.value) / Double(Self.colorScale)
      result["color"] = Self.argb(hue: color.hue, saturation: color.saturation)
    }
    return result
  }

  /// The data points for a command, or nil if this bulb cannot perform it.
  func dataPoints(for command: [String: Any], reported: [String: Any]) -> [String: Any]? {
    var result: [String: Any] = [:]
    let level = (command["brightness"] as? NSNumber)?.doubleValue
    let wantsWhite = (command["whiteMode"] as? NSNumber)?.boolValue ?? false
    if let argb = (command["color"] as? NSNumber)?.intValue {
      guard let modeDP, let colorDP else { return nil }
      let shown = activeColor(reported: reported)?.value ?? Self.colorScale
      let value = level.map(colorValue(forLevel:)) ?? shown
      let (hue, saturation) = Self.hueSaturation(argb: argb)
      result[modeDP] = Self.colorMode
      result[colorDP] = ColorValue(hue: hue, saturation: saturation, value: value).hex
      return result
    }
    if wantsWhite {
      guard let modeDP else { return nil }
      result[modeDP] = Self.whiteMode
    }
    if let kelvin = (command["temperature"] as? NSNumber)?.intValue {
      guard let temperature else { return nil }
      result[temperature.id] = dpValue(fromKelvin: kelvin, temperature)
    }
    if let level {
      if !wantsWhite, let colorDP, let color = activeColor(reported: reported) {
        result[colorDP] = ColorValue(hue: color.hue, saturation: color.saturation,
          value: colorValue(forLevel: level)).hex
      } else {
        guard let brightness else { return nil }
        let value = Int((level * Double(brightness.max)).rounded())
        result[brightness.id] = Swift.min(Swift.max(value, brightness.min), brightness.max)
      }
    }
    return result
  }

  private func activeColor(reported: [String: Any]) -> ColorValue? {
    guard let modeDP, let colorDP, reported[modeDP] as? String == Self.colorMode,
      let hex = reported[colorDP] as? String else { return nil }
    return ColorValue(hex: hex)
  }

  private func colorValue(forLevel level: Double) -> Int {
    let value = Int((level * Double(Self.colorScale)).rounded())
    return Swift.min(Swift.max(value, Self.minimumColorValue), Self.colorScale)
  }

  private func number(_ value: Any?) -> Int? { (value as? NSNumber)?.intValue }

  private func kelvin(fromDP value: Int, _ dp: ValueDP) -> Int {
    let position = Double(value - dp.min) / Double(dp.max - dp.min)
    let span = Double(Self.nominalCoolKelvin - Self.nominalWarmKelvin)
    return Self.nominalWarmKelvin + Int((position * span).rounded())
  }

  private func dpValue(fromKelvin kelvin: Int, _ dp: ValueDP) -> Int {
    let span = Double(Self.nominalCoolKelvin - Self.nominalWarmKelvin)
    let position = Double(kelvin - Self.nominalWarmKelvin) / span
    let value = dp.min + Int((position * Double(dp.max - dp.min)).rounded())
    return Swift.min(Swift.max(value, dp.min), dp.max)
  }

  static func hueSaturation(argb: Int) -> (hue: Int, saturation: Int) {
    let red = Double((argb >> 16) & 0xFF) / 255
    let green = Double((argb >> 8) & 0xFF) / 255
    let blue = Double(argb & 0xFF) / 255
    let top = Swift.max(red, green, blue)
    let spread = top - Swift.min(red, green, blue)
    guard spread > 0 else { return (0, 0) }
    var hue: Double
    if top == red {
      hue = (green - blue) / spread
    } else if top == green {
      hue = (blue - red) / spread + 2
    } else {
      hue = (red - green) / spread + 4
    }
    hue *= 60
    if hue < 0 { hue += 360 }
    return (Int(hue.rounded()), Int((spread / top * Double(colorScale)).rounded()))
  }

  /// Full-brightness color for display. Brightness is reported separately.
  static func argb(hue: Int, saturation: Int) -> Int {
    let chroma = Double(saturation) / Double(colorScale)
    let sector = Double(hue % 360) / 60
    let middle = chroma * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
    let floor = 1 - chroma
    let (red, green, blue): (Double, Double, Double)
    switch Int(sector) {
    case 0: (red, green, blue) = (chroma, middle, 0)
    case 1: (red, green, blue) = (middle, chroma, 0)
    case 2: (red, green, blue) = (0, chroma, middle)
    case 3: (red, green, blue) = (0, middle, chroma)
    case 4: (red, green, blue) = (middle, 0, chroma)
    default: (red, green, blue) = (chroma, 0, middle)
    }
    func byte(_ part: Double) -> Int { Int(((part + floor) * 255).rounded()) }
    return 0xFF00_0000 | byte(red) << 16 | byte(green) << 8 | byte(blue)
  }
}
