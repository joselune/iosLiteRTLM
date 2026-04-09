//
//  ModelRepository.swift
//  ailocalagent
//
//  Created by Jose Luna on 07/04/2026.
//

import Foundation

struct ModelManifest: Codable, Equatable, Sendable {
    let version: String
    let fileName: String
    let installedAt: Date
    let sourceURL: URL?
}

protocol ModelRepository {
    func installState() async -> ModelInstallState

    func localModelURL() throws -> URL
    func localManifestURL() throws -> URL

    func loadManifest() async throws -> ModelManifest?
    func saveManifest(_ manifest: ModelManifest) async throws
    func clearInstallation() async throws

    func modelExists(with name: String?) async -> Bool
}
