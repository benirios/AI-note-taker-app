//
//  Note.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import Foundation
import SwiftData

@Model
final class Note: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var body: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, body: String, tags: [String] = [], createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.body = body
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
