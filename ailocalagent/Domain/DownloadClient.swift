//
//  DownloadClient.swift
//  ailocalagent
//
//  Created by Jose Luna on 07/04/2026.
//

import Foundation

enum DownloadEvent: Equatable, Sendable {
    case progress(Double)
    case finished
}

enum DownloadClientError: LocalizedError {
    case missingHuggingFaceToken

    var errorDescription: String? {
        switch self {
        case .missingHuggingFaceToken:
            return "Missing Hugging Face token. Create ailocalagent/Config/Secrets.xcconfig with \(Constants.HF_TOKEN_INFO_KEY) set before downloading the model."
        }
    }
}

protocol DownloadClient {
    func download(
        from remoteURL: URL,
        to localURL: URL
    ) -> AsyncThrowingStream<DownloadEvent, Error>
}

final class URLSessionDownloadClient: NSObject, DownloadClient, URLSessionDelegate {
    private struct DownloadState {
        let continuation: AsyncThrowingStream<DownloadEvent, Error>.Continuation
        let destinationURL: URL
    }

    private var session: URLSession!
    private var downloads: [Int: DownloadState] = [:]
    private let lock = NSLock()


    override init() {
        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60 * 60 * 24

        session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }

    func download(
            from remoteURL: URL,
            to localURL: URL
        ) -> AsyncThrowingStream<DownloadEvent, Error> {
            AsyncThrowingStream { continuation in
                do {
                    guard let rawToken = Bundle.main.object(forInfoDictionaryKey: Constants.HF_TOKEN_INFO_KEY) as? String else {
                        throw DownloadClientError.missingHuggingFaceToken
                    }

                    let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard token.isEmpty == false else {
                        throw DownloadClientError.missingHuggingFaceToken
                    }

                    let parent = localURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(
                        at: parent,
                        withIntermediateDirectories: true
                    )

                    // Remove stale file if present
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }

                    var request = URLRequest(url: remoteURL)
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                    let task = session.downloadTask(with: request)

                    lock.lock()
                    downloads[task.taskIdentifier] = DownloadState(
                        continuation: continuation,
                        destinationURL: localURL
                    )
                    lock.unlock()

                    continuation.onTermination = { [weak self] _ in
                        task.cancel()
                        if let self {
                            removeDownloadState(for: task.taskIdentifier)
                        }
                    }

                    task.resume()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

    private func removeDownloadState(for taskID: Int) {
        lock.lock()
        downloads.removeValue(forKey: taskID)
        lock.unlock()
    }

    private func state(for taskID: Int) -> DownloadState? {
        lock.lock()
        defer { lock.unlock() }
        return downloads[taskID]
    }
}

extension URLSessionDownloadClient: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard
            totalBytesExpectedToWrite > 0,
            let state = state(for: downloadTask.taskIdentifier)
        else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        state.continuation.yield(.progress(progress))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let state = state(for: downloadTask.taskIdentifier) else { return }

        do {
            let fm = FileManager.default

            if fm.fileExists(atPath: state.destinationURL.path) {
                try fm.removeItem(at: state.destinationURL)
            }

            try fm.moveItem(at: location, to: state.destinationURL)
            state.continuation.yield(.finished)
            state.continuation.finish()
        } catch {
            state.continuation.finish(throwing: error)
        }

        removeDownloadState(for: downloadTask.taskIdentifier)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error, let state = state(for: task.taskIdentifier) else { return }
        state.continuation.finish(throwing: error)
        removeDownloadState(for: task.taskIdentifier)
    }
}
