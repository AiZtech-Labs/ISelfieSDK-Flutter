import Foundation
import ISelfieSDK
import UIKit

// Translates between the Pigeon wire types and the native SDK's types, so neither leaks into
// the other.

// MARK: - Dart → native

extension EnvironmentMessage {
  /// Nil when a custom URL can't even be parsed; the native SDK checks the rest (https only).
  func toNative() -> ISelfieCardio.Environment? {
    switch kind {
    case .production: return .production
    case .development: return .development
    case .custom: return customUrl.flatMap(URL.init(string:)).map { .custom($0) }
    }
  }
}

extension EntitlementSourceMessage {
  func toNative() -> ISelfieCardio.EntitlementSource {
    switch self {
    case .auto: return .auto
    case .rbac: return .rbac
    case .legacy: return .legacy
    }
  }
}

extension LogLevelMessage {
  func toNative() -> ISelfieCardio.LogLevel {
    switch self {
    case .off: return .off
    case .basic: return .basic
    case .verbose: return .verbose
    }
  }
}

extension CardioLanguageMessage {
  func toNative() -> CardioLanguage {
    switch self {
    case .english: return .english
    case .spanish: return .spanish
    case .arabic: return .arabic
    }
  }
}

extension UIColor {
  /// From an ARGB 32-bit value (0xAARRGGBB).
  convenience init(argb: Int64) {
    self.init(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255
    )
  }

  /// Follows the device's light/dark setting, live — like `CardioStyle.system` does.
  static func adaptive(light: UIColor, dark: UIColor) -> UIColor {
    UIColor { $0.userInterfaceStyle == .dark ? dark : light }
  }
}

extension CardioStyleMessage {
  func toNative() -> CardioStyle {
    guard let darkPalette else {
      return palette.toNative(fontFace: fontFamily)
    }
    let light = palette.toNative(fontFace: fontFamily)
    let dark = darkPalette.toNative(fontFace: fontFamily)
    // The same number of gradient stops in both modes, so each stop can switch color.
    let stopCount = max(light.pageBackgroundColors.count, dark.pageBackgroundColors.count)
    let lightStops = Self.padded(light.pageBackgroundColors, to: stopCount)
    let darkStops = Self.padded(dark.pageBackgroundColors, to: stopCount)
    return CardioStyle(
      pageBackgroundColors: zip(lightStops, darkStops).map { UIColor.adaptive(light: $0, dark: $1) },
      cardBackgroundColor: .adaptive(light: light.cardBackgroundColor, dark: dark.cardBackgroundColor),
      cardHeaderBackgroundColor: .adaptive(light: light.cardHeaderBackgroundColor, dark: dark.cardHeaderBackgroundColor),
      primaryTextColor: .adaptive(light: light.primaryTextColor, dark: dark.primaryTextColor),
      secondaryTextColor: .adaptive(light: light.secondaryTextColor, dark: dark.secondaryTextColor),
      buttonColor: .adaptive(light: light.buttonColor, dark: dark.buttonColor),
      buttonTextColor: .adaptive(light: light.buttonTextColor, dark: dark.buttonTextColor),
      iconColor: .adaptive(light: light.iconColor, dark: dark.iconColor),
      fontFace: fontFamily,
      interfaceStyle: .unspecified
    )
  }

  /// Repeats the last stop until there are `count` (a single color stays a plain background).
  private static func padded(_ stops: [UIColor], to count: Int) -> [UIColor] {
    guard let last = stops.last else { return Array(repeating: .clear, count: count) }
    return stops + Array(repeating: last, count: max(0, count - stops.count))
  }
}

extension CardioPaletteMessage {
  func toNative(fontFace: String?) -> CardioStyle {
    CardioStyle(
      pageBackgroundColors: pageBackgroundColors.map(UIColor.init(argb:)),
      cardBackgroundColor: UIColor(argb: cardBackgroundColor),
      cardHeaderBackgroundColor: UIColor(argb: cardHeaderBackgroundColor),
      primaryTextColor: UIColor(argb: primaryTextColor),
      secondaryTextColor: UIColor(argb: secondaryTextColor),
      buttonColor: UIColor(argb: buttonColor),
      buttonTextColor: UIColor(argb: buttonTextColor),
      iconColor: UIColor(argb: iconColor),
      fontFace: fontFace,
      interfaceStyle: isDark ? .dark : .light
    )
  }
}

extension Array where Element == InstructionTranslationMessage {
  func toNative() -> CardioInstructionContent {
    CardioInstructionContent(translations: map { translation in
      let body: CardioInstructionContent.Body
      if let html = translation.html {
        body = .html(html)
      } else {
        body = .items((translation.items ?? []).map { item in
          CardioInstructionContent.Item(
            icon: item.iconUrl.flatMap(URL.init(string:)),
            title: item.title,
            subtitle: item.subtitle
          )
        })
      }
      return CardioInstructionContent.Translation(
        language: translation.language.toNative(),
        isRightToLeft: translation.isRightToLeft,
        header: translation.header,
        body: body
      )
    })
  }
}

extension ProgressBarPositionMessage {
  func toNative() -> ISelfieCameraCardioView.ProgressBarPosition {
    switch self {
    case .top: return .top
    case .bottom: return .bottom
    }
  }
}

extension CardioTestOptionsMessage {
  func toNative() -> CardioTestOptions {
    var options = CardioTestOptions()
    options.language = language.toNative()
    options.style = style.toNative()
    options.showLanguageSelector = showLanguageSelector
    options.instructionPage = CardioInstructionPage(
      hidden: instructionPageHidden,
      content: instructionContent?.toNative(),
      allowsDontShowAgain: instructionPageAllowsDontShowAgain
    )
    options.displayResults = displayResults
    // An unknown id keeps the device's zone.
    if let timeZone = timeZoneId.flatMap(TimeZone.init(identifier:)) {
      options.timeZone = timeZone
    }
    options.enableResultSharing = enableResultSharing
    options.disableAudio = disableAudio
    options.disableMotionDetection = disableMotionDetection
    options.disableLightCheck = disableLightCheck
    options.disableDistanceCheck = disableDistanceCheck
    options.terminateTestIfConditionPersisted = terminateTestIfConditionPersisted
    options.testTerminationTimeOut = testTerminationTimeOut
    options.progressBarPosition = progressBarPosition.toNative()
    options.enableMobileCameraSwap = enableMobileCameraSwap
    return options
  }
}

// MARK: - Native → Dart

extension CardioError {
  func toMessage() -> CardioErrorMessage {
    CardioErrorMessage(code: code?.rawValue, message: message)
  }
}

extension ISelfieCardio.Availability {
  func toMessage() -> AvailabilityMessage {
    AvailabilityMessage(isAvailable: isAvailable, error: error?.toMessage())
  }
}

extension CardioResult {
  func toMessage() -> CardioResultMessage {
    CardioResultMessage(
      testId: testId,
      createdAtMillis: createdAt.map { Int64(($0.timeIntervalSince1970 * 1000).rounded()) },
      heartRate: heartRate.map(Int64.init),
      heartRateConfidence: heartRateConfidence,
      bloodPressure: bloodPressure.map {
        BloodPressureMessage(systolic: Int64($0.systolic), diastolic: Int64($0.diastolic), label: $0.label)
      },
      spo2: spo2.map(Int64.init),
      hrv: hrv.map(Int64.init),
      respiratoryRate: respiratoryRate.map(Int64.init),
      appUserId: appUserId,
      elapsedSeconds: elapsed,
      rawJson: Self.json(raw)
    )
  }

  /// The server response comes from JSON, so it always serializes; "{}" only guards the API.
  private static func json(_ object: [String: Any]) -> String {
    guard JSONSerialization.isValidJSONObject(object),
          let data = try? JSONSerialization.data(withJSONObject: object),
          let string = String(data: data, encoding: .utf8)
    else { return "{}" }
    return string
  }
}

extension CardioScanFailure {
  func toMessage() -> CardioScanFailureMessage {
    switch self {
    case .unavailable(let error): return CardioScanFailureMessage(kind: .unavailable, error: error.toMessage())
    case .resultError(let error): return CardioScanFailureMessage(kind: .resultError, error: error.toMessage())
    case .tooManyInvalidFrames: return CardioScanFailureMessage(kind: .tooManyInvalidFrames)
    case .interrupted: return CardioScanFailureMessage(kind: .interrupted)
    case .cameraPermissionDenied: return CardioScanFailureMessage(kind: .cameraPermissionDenied)
    case .cancelled: return CardioScanFailureMessage(kind: .cancelled)
    }
  }
}

extension CardioTestStatus {
  func toMessage() -> CardioTestStatusMessage {
    switch self {
    case .instructions: return CardioTestStatusMessage(step: .instructions)
    case .started: return CardioTestStatusMessage(step: .started)
    case .inProgress: return CardioTestStatusMessage(step: .inProgress)
    case .processing: return CardioTestStatusMessage(step: .processing)
    case .completed: return CardioTestStatusMessage(step: .completed)
    case .failed(let failure): return CardioTestStatusMessage(step: .failed, failure: failure.toMessage())
    case .cancelled: return CardioTestStatusMessage(step: .cancelled)
    }
  }
}
