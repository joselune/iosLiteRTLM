//
//  ModelSetupState.swift
//  ailocalagent
//
//  Created by Jose Luna on 07/04/2026.
//

import Foundation

enum ModelSetupState: Equatable {
    case checking
    case notInstalled
    case downloading(progress: Double)
    case ready
    case error(message: String)
}
