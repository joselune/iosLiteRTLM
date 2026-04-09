# iosLiteRTLM

SwiftUI sample app for running a local LiteRT-LM model on Apple platforms.

This project is the app-side integration for our Apple bridge work. The runtime itself comes from the `LiteRT-LM` repository, where we package an Apple framework and expose the engine surface needed by the app. This repo focuses on the SwiftUI flow, local model download, and calling the packaged bridge from Swift.

## What This App Does

- Downloads a `.litertlm` model from Hugging Face into `Application Support/Models`
- Loads that model through `LiteRTKit`
- Runs local inference from SwiftUI
- Supports chat, streaming responses, reset, and re-download
- Targets Apple platforms with the bundled framework checked into `Frameworks/`

## Architecture

The app has a simple split between UI flow and inference integration:

- `ailocalagent/App`: top-level app flow and screen switching
- `ailocalagent/Features/Setup`: model existence checks and download orchestration
- `ailocalagent/Features/Chat`: chat state and prompt/response flow
- `ailocalagent/Domain`: abstractions for inference and download behavior
- `ailocalagent/Infrastructure/AI`: app-side integration with the packaged LiteRT bridge
- `Frameworks/LiteRTKit.xcframework`: compiled Apple framework used by the app

The startup flow is:

1. Check whether the model exists locally
2. If missing, show the download screen
3. Download the model with a Hugging Face bearer token
4. Create `LiteRTInferenceService`
5. Load the model and start local chat inference

## LiteRT-LM Bridge

The underlying engine is built from the local `LiteRT-LM` workspace.

Relevant context from that repo:

- Apple packaging output lives under `LiteRT-LM/out/apple`
- The generated engine artifact there is `LiteRTLMEngine.xcframework`
- The suggested app-side integration from that workspace is:
  - link the xcframework in Xcode
  - include the public headers
  - call the LiteRT-LM C API from `c/engine.h`

In this app repo, that engine surface is already wrapped into the checked-in `LiteRTKit.xcframework`, and the Swift app talks to it through `ailocalagent/Infrastructure/AI/LiteRTInferenceService.swift`.

## Local Token Setup

The Hugging Face token is intentionally not stored in source control.

This repo uses an iOS/macOS-friendly local config setup:

1. Create a Hugging Face access token in your Hugging Face account
2. Copy `ailocalagent/Config/Secrets.xcconfig.example` to `ailocalagent/Config/Secrets.xcconfig`
3. Open `ailocalagent/Config/Secrets.xcconfig`
4. Set your token on the `HF_TOKEN` line:

```xcconfig
HF_TOKEN = your_hugging_face_token_here
```

Example:

```xcconfig
HF_TOKEN = hf_your_real_token_here
```

You can also create the file from Terminal:

```bash
cp ailocalagent/Config/Secrets.xcconfig.example ailocalagent/Config/Secrets.xcconfig
```

5. Build and run

`ailocalagent/Config/BuildSettings.xcconfig` includes the local secrets file when present and injects `HF_TOKEN` into the generated app `Info.plist`.

The local secret file is ignored by Git. Only the example file is committed.

## Model Setup

The current app is configured to download:

- model: `gemma-4-E2B-it.litertlm`
- source: Hugging Face

See `ailocalagent/Constants/Constants.swift` for the current model name and download URL.

## Frameworks

`Frameworks/LiteRTKit.xcframework` is part of the project on purpose and is expected to be committed.

That framework is the bridge between the Swift app and the LiteRT-LM engine packaging work. This repo does not rebuild the native engine during normal app development.

## Current Integration Surface

The main inference entry point in the app is `ailocalagent/Infrastructure/AI/LiteRTInferenceService.swift`.

It currently:

- creates a `GemmaLocalEngine`
- loads the selected model path
- supports CPU/backend selection
- exposes full-response generation
- exposes streaming token generation
- supports cancellation and reset

## Notes

- The previous README content described an early scaffold plan and no longer matched the real project state.
- This repo now represents a working Apple app integration around a compiled LiteRT bridge and local model download flow.
