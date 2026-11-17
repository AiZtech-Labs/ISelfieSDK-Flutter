package ai.iselfie.sdk.flutter

import ai.iselfie.sdk.cardio.CardioError
import ai.iselfie.sdk.cardio.CardioInstructionContent
import ai.iselfie.sdk.cardio.CardioInstructionPage
import ai.iselfie.sdk.cardio.CardioLanguage
import ai.iselfie.sdk.cardio.CardioResult
import ai.iselfie.sdk.cardio.CardioScanFailure
import ai.iselfie.sdk.cardio.CardioStyle
import ai.iselfie.sdk.cardio.CardioTestOptions
import ai.iselfie.sdk.cardio.CardioTestStatus
import ai.iselfie.sdk.cardio.ISelfieCameraCardioView
import ai.iselfie.sdk.cardio.ISelfieCardio
import android.graphics.Typeface
import java.util.TimeZone
import org.json.JSONObject

// Translates between the Pigeon wire types and the native SDK's types, so neither leaks into
// the other.

// region Dart → native

internal fun EnvironmentMessage.toNative(): ISelfieCardio.Environment = when (kind) {
  EnvironmentKindMessage.PRODUCTION -> ISelfieCardio.Environment.Production
  EnvironmentKindMessage.DEVELOPMENT -> ISelfieCardio.Environment.Development
  // An empty URL is refused by the native SDK's own https check, with its usual error.
  EnvironmentKindMessage.CUSTOM -> ISelfieCardio.Environment.Custom(customUrl.orEmpty())
}

internal fun EntitlementSourceMessage.toNative(): ISelfieCardio.EntitlementSource = when (this) {
  EntitlementSourceMessage.AUTO -> ISelfieCardio.EntitlementSource.AUTO
  EntitlementSourceMessage.RBAC -> ISelfieCardio.EntitlementSource.RBAC
  EntitlementSourceMessage.LEGACY -> ISelfieCardio.EntitlementSource.LEGACY
}

internal fun LogLevelMessage.toNative(): ISelfieCardio.LogLevel = when (this) {
  LogLevelMessage.OFF -> ISelfieCardio.LogLevel.OFF
  LogLevelMessage.BASIC -> ISelfieCardio.LogLevel.BASIC
  LogLevelMessage.VERBOSE -> ISelfieCardio.LogLevel.VERBOSE
}

internal fun CardioLanguageMessage.toNative(): CardioLanguage = when (this) {
  CardioLanguageMessage.ENGLISH -> CardioLanguage.ENGLISH
  CardioLanguageMessage.SPANISH -> CardioLanguage.SPANISH
  CardioLanguageMessage.ARABIC -> CardioLanguage.ARABIC
}

/** Colors arrive as ARGB 32-bit values: their low 32 bits are an Android color int. */
private fun Long.toColorInt(): Int = toInt()

private fun CardioPaletteMessage.toNative(typeface: Typeface?): CardioStyle = CardioStyle(
  pageBackgroundColors = pageBackgroundColors.map { it.toColorInt() },
  cardBackgroundColor = cardBackgroundColor.toColorInt(),
  cardHeaderBackgroundColor = cardHeaderBackgroundColor.toColorInt(),
  primaryTextColor = primaryTextColor.toColorInt(),
  secondaryTextColor = secondaryTextColor.toColorInt(),
  buttonColor = buttonColor.toColorInt(),
  buttonTextColor = buttonTextColor.toColorInt(),
  iconColor = iconColor.toColorInt(),
  typeface = typeface,
  isDark = isDark,
)

internal fun CardioStyleMessage.toNative(): CardioStyle {
  // A family the system doesn't know falls back to the default font.
  val typeface = fontFamily?.let { Typeface.create(it, Typeface.NORMAL) }
  return palette.toNative(typeface).copy(darkVariant = darkPalette?.toNative(typeface))
}

internal fun List<InstructionTranslationMessage>.toNative() = CardioInstructionContent(
  map { translation ->
    val html = translation.html
    CardioInstructionContent.Translation(
      language = translation.language.toNative(),
      header = translation.header,
      body = if (html != null) {
        CardioInstructionContent.Body.Html(html)
      } else {
        CardioInstructionContent.Body.Items(
          translation.items.orEmpty().map { CardioInstructionContent.Item(it.title, it.subtitle, it.iconUrl) },
        )
      },
      isRightToLeft = translation.isRightToLeft,
    )
  },
)

internal fun ProgressBarPositionMessage.toNative(): ISelfieCameraCardioView.ProgressBarPosition =
  when (this) {
    ProgressBarPositionMessage.TOP -> ISelfieCameraCardioView.ProgressBarPosition.TOP
    ProgressBarPositionMessage.BOTTOM -> ISelfieCameraCardioView.ProgressBarPosition.BOTTOM
  }

internal fun CardioTestOptionsMessage.toNative(): CardioTestOptions {
  val message = this
  return CardioTestOptions().apply {
    language = message.language.toNative()
    style = message.style.toNative()
    showLanguageSelector = message.showLanguageSelector
    instructionPage = CardioInstructionPage(
      hidden = message.instructionPageHidden,
      content = message.instructionContent?.toNative(),
      allowsDontShowAgain = message.instructionPageAllowsDontShowAgain,
    )
    displayResults = message.displayResults
    // An unknown id falls back to the device's zone rather than to GMT, which getTimeZone does.
    message.timeZoneId
      ?.takeIf { it in TimeZone.getAvailableIDs() }
      ?.let { timeZone = TimeZone.getTimeZone(it) }
    enableResultSharing = message.enableResultSharing
    disableAudio = message.disableAudio
    disableMotionDetection = message.disableMotionDetection
    disableLightCheck = message.disableLightCheck
    disableDistanceCheck = message.disableDistanceCheck
    terminateTestIfConditionPersisted = message.terminateTestIfConditionPersisted
    testTerminationTimeOut = message.testTerminationTimeOut
    progressBarPosition = message.progressBarPosition.toNative()
    enableMobileCameraSwap = message.enableMobileCameraSwap
  }
}

// endregion

// region Native → Dart

internal fun CardioError.toMessage() = CardioErrorMessage(code = code?.value, message = message)

internal fun ISelfieCardio.Availability.toMessage() =
  AvailabilityMessage(isAvailable = isAvailable, error = error?.toMessage())

internal fun CardioResult.toMessage() = CardioResultMessage(
  testId = testId,
  createdAtMillis = createdAt?.time,
  heartRate = heartRate?.toLong(),
  heartRateConfidence = heartRateConfidence,
  bloodPressure = bloodPressure?.let {
    BloodPressureMessage(systolic = it.systolic.toLong(), diastolic = it.diastolic.toLong(), label = it.label)
  },
  spo2 = spo2?.toLong(),
  hrv = hrv?.toLong(),
  respiratoryRate = respiratoryRate?.toLong(),
  appUserId = appUserId,
  elapsedSeconds = elapsed,
  rawJson = JSONObject(raw).toString(),
)

internal fun CardioScanFailure.toMessage(): CardioScanFailureMessage = when (this) {
  is CardioScanFailure.Unavailable ->
    CardioScanFailureMessage(CardioScanFailureKindMessage.UNAVAILABLE, error.toMessage())
  is CardioScanFailure.ResultError ->
    CardioScanFailureMessage(CardioScanFailureKindMessage.RESULT_ERROR, error.toMessage())
  CardioScanFailure.TooManyInvalidFrames ->
    CardioScanFailureMessage(CardioScanFailureKindMessage.TOO_MANY_INVALID_FRAMES)
  CardioScanFailure.Interrupted -> CardioScanFailureMessage(CardioScanFailureKindMessage.INTERRUPTED)
  CardioScanFailure.CameraPermissionDenied ->
    CardioScanFailureMessage(CardioScanFailureKindMessage.CAMERA_PERMISSION_DENIED)
  CardioScanFailure.Cancelled -> CardioScanFailureMessage(CardioScanFailureKindMessage.CANCELLED)
}

internal fun CardioTestStatus.toMessage(): CardioTestStatusMessage = when (this) {
  CardioTestStatus.Instructions -> CardioTestStatusMessage(CardioTestStepMessage.INSTRUCTIONS)
  CardioTestStatus.Started -> CardioTestStatusMessage(CardioTestStepMessage.STARTED)
  CardioTestStatus.InProgress -> CardioTestStatusMessage(CardioTestStepMessage.IN_PROGRESS)
  CardioTestStatus.Processing -> CardioTestStatusMessage(CardioTestStepMessage.PROCESSING)
  CardioTestStatus.Completed -> CardioTestStatusMessage(CardioTestStepMessage.COMPLETED)
  is CardioTestStatus.Failed -> CardioTestStatusMessage(CardioTestStepMessage.FAILED, failure.toMessage())
  CardioTestStatus.Cancelled -> CardioTestStatusMessage(CardioTestStepMessage.CANCELLED)
}

// endregion
