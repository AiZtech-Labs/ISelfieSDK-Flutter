# iSelfie SDK for Flutter

Add the iSelfie heart health test to your Flutter app: instructions, face scan, result page and
sharing, with heart rate, blood pressure, SpO2, HRV and respiratory rate. The plugin runs the
native iSelfie SDKs for [iOS and Android](https://github.com/AiZtech-Labs/ISelfieSDK), so the test
looks and behaves the same as in a native app.

You need an iSelfie organization account: your **organization ID** and **API key** come from the
[iSelfie Developer Console](https://developer.iselfie.ai/). No account yet? Write to
[hi@iselfie.ai](mailto:hi@iselfie.ai).

## Contents

- [Requirements](#requirements)
- [Install](#install)
- [App setup](#app-setup)
- [Access tokens](#access-tokens)
- [Initialize](#initialize)
- [Start the test](#start-the-test)
- [Options](#options)
- [Styles and instructions](#styles-and-instructions)
- [Example app](#example-app)
- [License](#license)
- [Support](#support)

## Requirements

- Flutter 3.44 or newer, with Swift Package Manager on (the default since 3.44). CocoaPods isn't
  supported.
- iOS 15.1 or newer (iPhone). Android 7.0 (API 24) or newer.
- A real device for the scan: simulators and emulators have no usable front camera.

## Install

Add the plugin from this repository, pinned to a release tag:

```yaml
dependencies:
  iselfie_sdk:
    git:
      url: https://github.com/AiZtech-Labs/ISelfieSDK-Flutter
      ref: 1.0.0-rc.2
```

The plugin brings the matching native SDKs on its own: `ISelfieSDK` through Swift Package Manager
on iOS, and `ai.iselfie:iselfie-sdk` from Maven Central on Android.

## App setup

**iOS**

- Set the iOS deployment target to 15.1 or newer (Runner target, General → Minimum Deployments),
  then run `flutter clean`. Otherwise the build can still fail with "requires minimum platform
  version 15.1 … but this target supports 15.0", from an outdated generated package.
- Add `NSCameraUsageDescription` to `ios/Runner/Info.plist`, for example:

  ```xml
  <key>NSCameraUsageDescription</key>
  <string>The camera is used to measure your heart health.</string>
  ```

**Android**

- `minSdk` 24 or newer in `android/app/build.gradle.kts`.
- For Arabic (right to left), add `android:supportsRtl="true"` to `<application>` in
  `android/app/src/main/AndroidManifest.xml`. Flutter's template leaves it out, and without it
  Android lays the test out left to right.

The SDK asks for the camera permission itself when the test starts.

## Access tokens

The SDK authenticates with short-lived **access tokens** that **your backend** creates with your
API key. Your app only receives the token.

> **Never put your API key in the app.** Anything shipped in an app can be extracted.

How to create a token from your backend:
[Before you start: access tokens](https://github.com/AiZtech-Labs/ISelfieSDK#before-you-start-access-tokens).

## Initialize

Call `initialize` with a fresh token each time the user opens your test screen:

```dart
import 'package:iselfie_sdk/iselfie_sdk.dart';

final availability = await ISelfieCardio.initialize(
  accessToken: tokenFromYourBackend,
  organizationId: '<ORGANIZATION_ID>',
  appUserId: currentUser.internalId, // optional
);

if (!availability.isAvailable) {
  // availability.error is a CardioError, e.g. no plan or no tests left.
  showMessage(availability.error?.code);
}
```

`appUserId` is optional: your own ID for the user, stored with each test and sent in the webhook.
Use an **opaque internal ID**, never an email, phone number or national ID.

## Start the test

```dart
final outcome = await ISelfieCardio.startCardioTest(
  options: const CardioTestOptions(
    language: CardioLanguage.spanish,
    displayResults: true,
  ),
  onStatus: (status) => debugPrint('${status.step}'),
);

switch (outcome) {
  case CardioTestCompleted(:final result):
    // Every metric is nullable: your plan decides which ones you receive.
    debugPrint('HR ${result.heartRate}, SpO2 ${result.spo2}');
  case CardioTestFailed(failure: UnavailableFailure(:final error)):
    // The plan or the token doesn't allow a test. Nothing was shown to the user.
    debugPrint('Not available: ${error.code}');
  case CardioTestFailed(failure: CancelledFailure()):
    // The user closed the test.
    break;
  case CardioTestFailed(:final failure):
    // The user already saw why the test failed.
    debugPrint('$failure');
}
```

One test runs at a time. `onStatus` reports each step: `instructions`, `started`, `processing`,
`completed`, `failed`, `cancelled`.

The result also reaches your backend through your organization's webhook, even if the app closes
right after the test. Use the webhook as the source of truth for results.

Errors, failure reasons and the webhook are described in the
[ISelfieSDK documentation](https://github.com/AiZtech-Labs/ISelfieSDK#errors).

## Options

`CardioTestOptions` has the same options as the native SDKs:

| Option | Default |
|---|---|
| `language` | `CardioLanguage.english` |
| `style` | `CardioStyle.system` |
| `showLanguageSelector` | `true` |
| `instructionPage` | `CardioInstructionPage()` |
| `displayResults` | `false` |
| `timeZoneId` | device time zone |
| `enableResultSharing` | `false` |
| `disableAudio` | `false` |
| `disableMotionDetection` | `false` |
| `disableLightCheck` | `false` |
| `disableDistanceCheck` | `false` |
| `terminateTestIfConditionPersisted` | `true` |
| `testTerminationTimeOut` | `Duration(seconds: 7)` |
| `progressBarPosition` | `CardioProgressBarPosition.top` |
| `enableMobileCameraSwap` | `false` |

What each option does: [Options](https://github.com/AiZtech-Labs/ISelfieSDK#options).

## Styles and instructions

- **Styles:** `CardioStyle.system` (follows light/dark), `CardioStyle.light` or
  `CardioStyle.dark`, or your own `CardioStyle(palette: …, darkPalette: …, fontFamily: …)`
  starting from `CardioPalette.light` / `CardioPalette.dark`.
- **Instruction page:** hide it, replace its content with your own items or HTML
  (`CardioInstructionContent`, also from the web SDK's JSON with `CardioInstructionContent.fromWebJson`),
  or let users skip it next time (`allowsDontShowAgain`; reset it with
  `ISelfieCardio.resetInstructionPageDontShowAgain()`).

Details: [Styles](https://github.com/AiZtech-Labs/ISelfieSDK#styles) and
[Instruction page](https://github.com/AiZtech-Labs/ISelfieSDK#instruction-page).

## Example app

`example/` shows every option. It creates the access token inside the app **for testing only**,
with a test organization's API key:

```bash
cd example && flutter run
```

Sign in with the environment, organization ID and API key of a **test** organization. The app
keeps them on the device (Keychain on iOS, encrypted storage on Android) and opens straight on the
test screen next time; **Sign out** forgets them.

To prefill the sign-in form, copy `example/config/example.json.template` to
`example/config/example.json`, fill it in, and run with
`--dart-define-from-file=config/example.json`.

## License

The iSelfie SDK is proprietary software of AiZtech Labs Inc., licensed under the
[iSelfie SDK License Agreement](https://www.iselfie.ai/sdk-license) (also in [LICENSE](LICENSE)).
It works only with an iSelfie organization account that has an active plan or free trial.
Third-party components are listed in [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).

## Support

Questions about the SDK, your plan or your account: **hi@iselfie.ai**.

Changes in each version: [CHANGELOG](CHANGELOG.md).
