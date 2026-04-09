//
//  ChatMessage.swift
//  ailocalagent
//
//  Created by Jose Luna on 07/04/2026.
//

import Foundation

struct ChatMessage: Identifiable, Equatable, Sendable {
    enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    var text: String
    let createdAt: Date

    init(role: Role, text: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }

}
