import Flutter
import ISelfieSDK
import UIKit

/// Forwards the Dart API to the native iSelfie SDK. Holds no logic of its own.
public final class ISelfieSdkPlugin: NSObject, FlutterPlugin, ISelfieCardioHostApi {
  private let flutterApi: ISelfieCardioFlutterApi

  /// The test that's open (or checking the plan), so a second start can't orphan its caller.
  private var openTest: ISelfieCardioTestViewController?

  init(flutterApi: ISelfieCardioFlutterApi) {
    self.flutterApi = flutterApi
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let plugin = ISelfieSdkPlugin(flutterApi: ISelfieCardioFlutterApi(binaryMessenger: messenger))
    ISelfieCardioHostApiSetup.setUp(binaryMessenger: messenger, api: plugin)
  }

  // MARK: - ISelfieCardioHostApi

  func initialize(request: InitializeRequest) async throws -> AvailabilityMessage {
    let environment: ISelfieCardio.Environment
    if let message = request.environment {
      guard let native = message.toNative() else {
        return AvailabilityMessage(
          isAvailable: false,
          error: CardioErrorMessage(
            code: nil,
            message: "Environment.custom must be an https URL (got \(message.customUrl ?? ""))"
          )
        )
      }
      environment = native
    } else {
      environment = .buildDefault
    }

    // The native completion always fires exactly once, on the main thread.
    return await withCheckedContinuation { continuation in
      ISelfieCardio.initialize(
        accessToken: request.accessToken,
        organizationId: request.organizationId,
        appUserId: request.appUserId,
        environment: environment,
        entitlementSource: request.entitlementSource.toNative()
      ) { availability in
        continuation.resume(returning: availability.toMessage())
      }
    }
  }

  func isInitialized() throws -> Bool {
    ISelfieCardio.isInitialized
  }

  func setLogLevel(level: LogLevelMessage) throws {
    ISelfieCardio.logLevel = level.toNative()
  }

  func startCardioTest(options: CardioTestOptionsMessage) async throws -> CardioTestOutcomeMessage {
    try await presentTest(options: options)
  }

  func isInstructionPageDismissedByUser() throws -> Bool {
    CardioInstructionPage.isDismissedByUser
  }

  func resetInstructionPageDontShowAgain() throws {
    CardioInstructionPage.resetDontShowAgain()
  }

  // MARK: - Helpers

  /// UIKit work, so on the main thread.
  @MainActor
  private func presentTest(options: CardioTestOptionsMessage) async throws -> CardioTestOutcomeMessage {
    guard openTest == nil else {
      throw PigeonError(code: "test-in-progress", message: "A cardio test is already open", details: nil)
    }
    guard let presenter = Self.topViewController() else {
      throw PigeonError(code: "no-view-controller", message: "No view controller to present the test from", details: nil)
    }

    let test = ISelfieCardioTestViewController(options: options.toNative())
    openTest = test
    defer { openTest = nil }

    // Exactly one of onCompleted / onFailed fires, on the main thread, when the test closes.
    return await withCheckedContinuation { continuation in
      test.onStatus = { [weak self] status in self?.send(status.toMessage()) }
      test.onCompleted = { result in
        continuation.resume(returning: CardioTestOutcomeMessage(result: result.toMessage()))
      }
      test.onFailed = { failure in
        continuation.resume(returning: CardioTestOutcomeMessage(failure: failure.toMessage()))
      }
      test.start(from: presenter)
    }
  }

  @MainActor
  private func send(_ status: CardioTestStatusMessage) {
    // A status the Dart side can't take (engine going away) is dropped: it's informational.
    Task { try? await flutterApi.onTestStatus(status: status) }
  }

  /// The view controller on top of the app's foreground window — the Flutter view, or whatever
  /// the app presented over it.
  @MainActor
  private static func topViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .flatMap(\.windows)
    var top = (windows.first(where: \.isKeyWindow) ?? windows.first)?.rootViewController
    while let presented = top?.presentedViewController, !presented.isBeingDismissed {
      top = presented
    }
    return top
  }
}
