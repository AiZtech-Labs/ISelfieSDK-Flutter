package ai.iselfie.sdk.flutter

import ai.iselfie.sdk.cardio.CardioInstructionPage
import ai.iselfie.sdk.cardio.ISelfieCardio
import ai.iselfie.sdk.cardio.ISelfieCardioTest
import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlin.coroutines.resume
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine

/** Forwards the Dart API to the native iSelfie SDK. Holds no logic of its own. */
class ISelfieSdkPlugin : FlutterPlugin, ActivityAware, ISelfieCardioHostApi {
  private var applicationContext: Context? = null
  private var activity: Activity? = null
  private var flutterApi: ISelfieCardioFlutterApi? = null
  private var scope: CoroutineScope? = null

  /** The test that's open (or checking the plan), so a second start can't orphan its caller. */
  private var openTest: ISelfieCardioTest? = null

  // region FlutterPlugin / ActivityAware

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = binding.applicationContext
    flutterApi = ISelfieCardioFlutterApi(binding.binaryMessenger)
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    ISelfieCardioHostApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    ISelfieCardioHostApi.setUp(binding.binaryMessenger, null)
    scope?.cancel()
    scope = null
    flutterApi = null
    applicationContext = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  // endregion

  // region ISelfieCardioHostApi

  override suspend fun initialize(request: InitializeRequest): AvailabilityMessage {
    val context = requireApplicationContext()
    // The native completion always fires exactly once, on the main thread.
    return suspendCancellableCoroutine { continuation ->
      ISelfieCardio.initialize(
        context = context,
        accessToken = request.accessToken,
        organizationId = request.organizationId,
        appUserId = request.appUserId,
        environment = request.environment?.toNative() ?: ISelfieCardio.Environment.buildDefault,
        entitlementSource = request.entitlementSource.toNative(),
      ) { availability ->
        if (continuation.isActive) continuation.resume(availability.toMessage())
      }
    }
  }

  override fun isInitialized(): Boolean = ISelfieCardio.isInitialized

  override fun setLogLevel(level: LogLevelMessage) {
    ISelfieCardio.logLevel = level.toNative()
  }

  override suspend fun startCardioTest(options: CardioTestOptionsMessage): CardioTestOutcomeMessage {
    if (openTest != null) throw FlutterError("test-in-progress", "A cardio test is already open")
    // Started from the Flutter activity, the test stacks on top of it in the same task.
    val context: Context = activity ?: requireApplicationContext()
    val test = ISelfieCardioTest(options.toNative())
    openTest = test
    return try {
      // Exactly one of onCompleted / onFailed fires, on the main thread, when the flow closes.
      suspendCancellableCoroutine { continuation ->
        test.onStatus = { status -> sendStatus(status.toMessage()) }
        test.onCompleted = { result ->
          if (continuation.isActive) continuation.resume(CardioTestOutcomeMessage(result = result.toMessage()))
        }
        test.onFailed = { failure ->
          if (continuation.isActive) continuation.resume(CardioTestOutcomeMessage(failure = failure.toMessage()))
        }
        test.start(context)
      }
    } finally {
      openTest = null
    }
  }

  override fun isInstructionPageDismissedByUser(): Boolean =
    CardioInstructionPage.isDismissedByUser(requireApplicationContext())

  override fun resetInstructionPageDontShowAgain() {
    CardioInstructionPage.resetDontShowAgain(requireApplicationContext())
  }

  // endregion

  private fun sendStatus(status: CardioTestStatusMessage) {
    val api = flutterApi ?: return
    // A status the Dart side can't take (engine going away) is dropped: it's informational.
    scope?.launch { runCatching { api.onTestStatus(status) } }
  }

  private fun requireApplicationContext(): Context = applicationContext
    ?: throw FlutterError("not-attached", "The iSelfie plugin isn't attached to a Flutter engine")
}
