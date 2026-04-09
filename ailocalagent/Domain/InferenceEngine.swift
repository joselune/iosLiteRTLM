import Foundation

enum AppBackend: String, CaseIterable {
    case cpu, gpu, npu
}

protocol InferenceEngine {
    func loadModel(at path: String, backend: AppBackend) async throws
    func generate(prompt: String) async throws -> String
    func generateStream(prompt: String) -> AsyncThrowingStream<String, Error>
    func cancelGeneration()
    func reset() async
}
