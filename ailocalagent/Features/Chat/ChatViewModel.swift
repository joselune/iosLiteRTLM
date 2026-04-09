import Foundation
import Observation

@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var screenState: ChatScreenState = .loadingModel
    var inputText = ""
    var showModelLoadedToast = false
    var requestDeleteAndRedownload = false
    var selectedBackend: AppBackend = .cpu
    var showErrorAlert = false
    var errorMessage = ""

    let modelURL: URL
    private let inference: InferenceEngine
    private var generationTask: Task<Void, Never>?

    var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    init(inference: InferenceEngine, modelURL: URL) {
        self.inference = inference
        self.modelURL = modelURL
    }

    func loadModel() async {
        screenState = .loadingModel
        do {
            try await inference.loadModel(at: modelURL.path, backend: selectedBackend)
            screenState = .idle
            showModelLoadedToast = true
        } catch {
            errorMessage = error.localizedDescription
            screenState = .error(message: errorMessage)
            showErrorAlert = true
        }
    }

    func fallbackToCPU() async {
        selectedBackend = .cpu
        await loadModel()
    }

    func deleteModelFile() {
        try? FileManager.default.removeItem(at: modelURL)
        requestDeleteAndRedownload = true
    }

    func newChat() async {
        inference.cancelGeneration()
        generationTask?.cancel()
        await generationTask?.value
        generationTask = nil
        screenState = .idle
        messages.removeAll()
        await inference.reset()
    }

    func stopGenerating() {
        inference.cancelGeneration()
        generationTask?.cancel()
    }

    func sendMessage() {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, screenState == .idle else { return }

        let userMsg = ChatMessage(role: .user, text: prompt)
        messages.append(userMsg)
        inputText = ""
        screenState = .generating

        generationTask = Task {
            var assistantIndex: Int?

            do {
                for try await chunk in inference.generateStream(prompt: prompt) {
                    if Task.isCancelled { break }
                    if assistantIndex == nil {
                        messages.append(ChatMessage(role: .assistant, text: chunk))
                        assistantIndex = messages.count - 1
                    } else {
                        messages[assistantIndex!].text += chunk
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                if let idx = assistantIndex, !messages[idx].text.isEmpty {
                    messages.append(ChatMessage(role: .system, text: "Generation stopped."))
                } else {
                    if let idx = assistantIndex {
                        messages.remove(at: idx)
                    }
                    messages.append(ChatMessage(role: .system, text: "Failed to generate response. Please try again."))
                }
            }
            if !Task.isCancelled {
                screenState = .idle
            }
        }
    }
}
