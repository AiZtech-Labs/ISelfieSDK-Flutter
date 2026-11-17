## 1.0.0-rc.1

First release candidate, on native iSelfie SDK 1.0.0-rc.1 (iOS and Android).


- `ISelfieCardio.initialize`, `isInitialized` and `setLogLevel` over the native iSelfie SDKs.
- `ISelfieCardio.startCardioTest`: the native ready-made test, with its options, status updates
  and a typed outcome (`CardioTestCompleted` / `CardioTestFailed`).
- Custom styles (`CardioStyle`, `CardioPalette`), custom instructions
  (`CardioInstructionContent`, `fromWebJson`) and the instructions page's "Don't show this again"
  (`isInstructionPageDismissedByUser`, `resetInstructionPageDontShowAgain`).
