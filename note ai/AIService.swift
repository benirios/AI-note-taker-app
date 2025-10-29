//
//  AIService.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import Foundation

protocol AIService {
    func answer(question: String, with contextSnippets: [ContextSnippet]) async throws -> String
}

struct ContextSnippet: Identifiable, Sendable {
    let id = UUID()
    let noteID: UUID
    let title: String
    let text: String
}
