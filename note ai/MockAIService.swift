//
//  MockAIService.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import Foundation

struct MockAIService: AIService {
    func answer(question: String, with contextSnippets: [ContextSnippet]) async throws -> String {
        let header = "Grounded Answer (mock):"
        let q = "Q: \(question)"
        let ctxHeader = "Based on these notes:"
        let bullets = contextSnippets.prefix(5).map { "- \($0.title): \($0.text.prefix(240))" }.joined(separator: "\n")
        let guidance = "\nIf the answer isn't in the notes, say you don't know."
        return [header, q, ctxHeader, bullets, guidance].joined(separator: "\n\n")
    }
}
