//
//  ModelInstallState.swift
//  ailocalagent
//
//  Created by Jose Luna on 07/04/2026.
//

import Foundation

enum ModelInstallState: Equatable, Sendable {
    case notInstalled
    case installed(ModelManifest)
    case failed(message: String)
}
