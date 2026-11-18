## 1.0.0-rc.2

On native iSelfie SDK 1.0.0-rc.2. No API changes.

- iOS: fixes App Store uploads. Apps using rc.1 were refused with ITMS-90535 ("Unexpected
  CFBundleExecutable Key" in `ISelfieSDKResources.bundle`).
- Android: the rear camera is no longer inferred as required by Google Play, so apps install on
  devices with only a front camera.

## 1.0.0-rc.1

First release candidate, on native iSelfie SDK 1.0.0-rc.1 (iOS and Android).


- `ISelfieCardio.initialize`, `isInitialized` and `setLogLevel` over the native iSelfie SDKs.
- `ISelfieCardio.startCardioTest`: the native ready-made test, with its options, status updates
  and a typed outcome (`CardioTestCompleted` / `CardioTestFailed`).
- Custom styles (`CardioStyle`, `CardioPalette`), custom instructions
  (`CardioInstructionContent`, `fromWebJson`) and the instructions page's "Don't show this again"
  (`isInstructionPageDismissedByUser`, `resetInstructionPageDontShowAgain`).
