import Foundation
import LiteRTKit

final class LiteRTInferenceService: InferenceEngine, @unchecked Sendable {
    private let engine = GemmaLocalEngine()
    private let queue = DispatchQueue(label: "ai.inference", qos: .userInitiated)

    func loadModel(at path: String, backend: AppBackend = .cpu) async throws {
        let inferenceBackend = InferenceBackend(rawValue: backend.rawValue) ?? .cpu
        try await runOnQueue {
            try syncAwait { try await self.engine.loadModel(at: path, backend: inferenceBackend) }
        }
    }

    func generate(prompt: String) async throws -> String {
        try await runOnQueue {
            let response = try syncAwait {
                try await self.engine.generate(prompt: prompt, config: InferenceConfig())
            }
            return response.text
        }
    }

    func generateStream(prompt: String) -> AsyncThrowingStream<String, Error> {
        engine.generateStream(prompt: prompt, config: InferenceConfig())
    }

    func cancelGeneration() {
        engine.cancelGeneration()
    }

    func reset() async {
        await withCheckedContinuation { cont in
            queue.async {
                syncAwaitVoid { await self.engine.reset() }
                cont.resume()
            }
        }
    }

    private func runOnQueue<T: Sendable>(_ work: @Sendable @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                do {
                    cont.resume(returning: try work())
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
}

private func syncAwait<T>(_ operation: @Sendable @escaping () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    nonisolated(unsafe) var result: Result<T, any Error>!
    Task {
        do {
            result = .success(try await operation())
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }
    semaphore.wait()
    return try result.get()
}

private func syncAwaitVoid(_ operation: @Sendable @escaping () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await operation()
        semaphore.signal()
    }
    semaphore.wait()
}
