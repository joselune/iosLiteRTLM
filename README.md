```txt
LocalGemmaChat/
  App/
    LocalGemmaChatApp.swift

  Features/
    Chat/
      ChatView.swift
      ChatViewModel.swift
      ChatMessage.swift
      ComposerView.swift
      MessageBubbleView.swift
      ChatScreenState.swift

    ModelSetup/
      ModelSetupView.swift
      ModelSetupViewModel.swift
      ModelSetupState.swift

  Domain/
    InferenceEngine.swift
    ModelRepository.swift
    DownloadClient.swift
    ModelInstallState.swift

  Infrastructure/
    AI/
      LiteRTInferenceService.swift
      LiteRTBridge.h
      LiteRTBridge.mm
      LiteRTRunner.hpp
      LiteRTRunner.cc

    Storage/
      LocalModelRepository.swift
      ModelManifest.swift

    Networking/
      URLSessionDownloadClient.swift

    Config/
      AppConfig.swift

  Shared/
    UI/
      LoadingView.swift
      ErrorBanner.swift

    Logging/
      AppLogger.swift
```

## Local setup

The app expects a local Hugging Face token through an ignored Xcode config file and does not store that token in source control.

1. Copy `ailocalagent/Config/Secrets.xcconfig.example` to `ailocalagent/Config/Secrets.xcconfig`
2. Replace the placeholder value with your local Hugging Face token
3. Build and run normally

`BuildSettings.xcconfig` includes `Secrets.xcconfig` when present and injects `HF_TOKEN` into the app's generated `Info.plist`.

`Frameworks/LiteRTKit.xcframework` is intended to stay in the project and can be committed.

### Stage 1 — Project scaffold and architecture foundation
Goal

Set up the app structure, dependency boundaries, and a fake vertical slice before touching model download or native inference.

Tasks
Create the Xcode SwiftUI project
Create the folder structure
Define core domain protocols:
InferenceEngine
ModelRepository
DownloadClient
Create initial models:
ChatMessage
ModelInstallState
ChatScreenState
Create mock implementations for:
fake inference
fake model repository
fake downloader
Build a minimal navigation flow:
if model not ready → show setup screen
if model ready → show chat screen
Add AppConfig for constants and model metadata placeholders

### Deliverables
App compiles and runs
Clean folder structure in place
Domain interfaces defined
Chat screen and setup screen both exist
App works end-to-end using mocks only
No native bridge yet

### Definition of done
You can launch the app and navigate through the intended flow
The UI does not depend on concrete infra classes directly
Mock inference can return a fake response
___
