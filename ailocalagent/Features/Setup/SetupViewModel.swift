//
//  SetupViewModel.swift
//  ailocalagent
//
//  Created by Jose Luna on 08/04/2026.
//

import Foundation
import Observation

@Observable
final class SetupViewModel {

    var modelSetupState: ModelSetupState = .checking
    private let downloadClient: DownloadClient

    init(downloadClient: DownloadClient = URLSessionDownloadClient()) {
        self.downloadClient = downloadClient
    }

    var isDownloading: Bool {
        if case .downloading = modelSetupState {
            return true
        }
        return false
    }

    var downloadProgress: Double? {
        if case let .downloading(progress) = modelSetupState {
            return progress
        }
        return nil
    }

    var navigateToApp: Bool {
        if case .ready = modelSetupState {
            return true
        }
        return false
    }

    func setup() async {
        modelSetupState = .checking
        await checkModel()
    }

    private func checkModel() async {
        do {
                let url = try modelLocalURL()
                if FileManager.default.fileExists(atPath: url.path) {
                    modelSetupState = .ready
                } else {
                    modelSetupState = .notInstalled
                }
            } catch {
                modelSetupState = .error(message: error.localizedDescription)
            }
    }

    func downloadModel() async {
            guard case .notInstalled = modelSetupState else { return }

            do {
                let remoteURL = try modelRemoteURL()
                let localURL = try modelLocalURL()

                for try await event in downloadClient.download(from: remoteURL, to: localURL) {
                    switch event {
                    case .progress(let value):
                        modelSetupState = .downloading(progress: value)

                    case .finished:
                        modelSetupState = .ready
                    }
                }
            } catch {
                modelSetupState = .error(message: error.localizedDescription)
            }
        }

    func modelLocalURL() throws -> URL {
           let base = try FileManager.default.url(
               for: .applicationSupportDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: true
           )

        let dir = base.appendingPathComponent(Constants.MODEL_FOLDER_NAME, isDirectory: true)
           try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        return dir.appendingPathComponent(Constants.MODEL_NAME)
       }

       private func modelRemoteURL() throws -> URL {
           guard let url = URL(string: Constants.MODEL_DOWNLOAD_URL) else {
               throw URLError(.badURL)
           }
           return url
       }

}
