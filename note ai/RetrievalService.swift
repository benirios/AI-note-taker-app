//
//  RetrievalService.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import Foundation

struct RetrievalService {

    func retrieveRelevantNotes(question: String, from notes: [Note], maxCount: Int = 8) -> [ContextSnippet] {
        let q = normalize(question)
        let qTokens = tokens(from: q)
        guard !qTokens.isEmpty else { return [] }

        struct Scored {
            let note: Note
            let score: Double
        }

        let scored: [Scored] = notes.map { note in
            let title = normalize(note.title)
            let body = normalize(note.body)
            let tags = normalize(note.tags.joined(separator: " "))

            let titleTokens = tokens(from: title)
            let bodyTokens = tokens(from: body)
            let tagTokens = tokens(from: tags)

            // Token-overlap scores (Jaccard-like and raw overlap)
            let titleOverlap = overlapScore(qTokens, titleTokens)
            let bodyOverlap = overlapScore(qTokens, bodyTokens)
            let tagOverlap = overlapScore(qTokens, tagTokens)

            // Weighted combination: titles matter most
            // Add a small bonus if exact phrase exists anywhere
            var s = 0.0
            s += 0.6 * titleOverlap
            s += 0.35 * bodyOverlap
            s += 0.05 * tagOverlap

            if !q.isEmpty {
                if title.contains(q) { s += 0.2 }
                if body.contains(q) { s += 0.1 }
                if tags.contains(q) { s += 0.05 }
            }

            // Slight length normalization to avoid very short accidental matches
            let lenPenalty = lengthPenalty(for: bodyTokens.count + titleTokens.count)
            s *= lenPenalty

            return Scored(note: note, score: s)
        }
        .filter { $0.score > 0.01 } // drop near-zero matches

        if scored.isEmpty { return [] }

        let sorted = scored.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.note.updatedAt > rhs.note.updatedAt
        }

        return sorted.prefix(maxCount).map { entry in
            let n = entry.note
            // Build a snippet around the most relevant part of the body
            let snippetText = bestSnippet(for: question, in: n.body)
            return ContextSnippet(
                noteID: n.id,
                title: n.title.isEmpty ? "Untitled" : n.title,
                text: snippetText
            )
        }
    }

    // MARK: - Scoring helpers

    private func overlapScore(_ a: [String], _ b: [String]) -> Double {
        if a.isEmpty || b.isEmpty { return 0 }
        let sa = Set(a)
        let sb = Set(b)
        let inter = sa.intersection(sb).count
        let denom = max(1, min(sa.count, sb.count))
        // Use normalized overlap (intersection over min size) to be forgiving
        return Double(inter) / Double(denom)
    }

    private func lengthPenalty(for tokenCount: Int) -> Double {
        // Penalize extremely short docs to reduce chance hits, but keep within [0.8, 1.0]
        if tokenCount <= 5 { return 0.85 }
        if tokenCount <= 10 { return 0.9 }
        return 1.0
    }

    // MARK: - Snippet selection

    private func bestSnippet(for query: String, in body: String, maxChars: Int = 600) -> String {
        let cleanedBody = body.replacingOccurrences(of: "\n", with: " ")
        if cleanedBody.isEmpty { return "" }

        // If exact phrase exists, center snippet around it
        let lowerBody = cleanedBody.lowercased()
        let lowerQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if let range = lowerBody.range(of: lowerQuery), !lowerQuery.isEmpty {
            let startIndex = cleanedBody.index(cleanedBody.startIndex, offsetBy: lowerBody.distance(from: lowerBody.startIndex, to: range.lowerBound))
            let endIndex = cleanedBody.index(cleanedBody.startIndex, offsetBy: lowerBody.distance(from: lowerBody.startIndex, to: range.upperBound))
            return centeredSnippet(in: cleanedBody, around: startIndex..<endIndex, maxChars: maxChars)
        }

        // Otherwise, choose the most relevant sentence
        let sentences = splitIntoSentences(cleanedBody)
        if sentences.isEmpty {
            return truncate(cleanedBody, maxChars: maxChars)
        }

        let qTokens = tokens(from: normalize(query))
        let scored = sentences.map { s -> (String, Double) in
            let sTokens = tokens(from: normalize(s))
            return (s, overlapScore(qTokens, sTokens))
        }
        .sorted { $0.1 > $1.1 }

        let best = scored.first?.0 ?? cleanedBody
        return truncate(best, maxChars: maxChars)
    }

    private func centeredSnippet(in text: String, around range: Range<String.Index>, maxChars: Int) -> String {
        if text.count <= maxChars { return text }
        let targetLen = maxChars
        let mid = range.lowerBound
        let start = text.index(mid, offsetBy: -min(targetLen/2, text.distance(from: text.startIndex, to: mid)), limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(start, offsetBy: targetLen, limitedBy: text.endIndex) ?? text.endIndex
        var snippet = String(text[start..<end])
        if start > text.startIndex { snippet = "…" + snippet }
        if end < text.endIndex { snippet += "…" }
        return snippet
    }

    private func truncate(_ text: String, maxChars: Int) -> String {
        if text.count <= maxChars { return text }
        return String(text.prefix(maxChars)) + "…"
    }

    // MARK: - Text utilities

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokens(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        return text.split(separator: " ").map(String.init)
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        // Simple sentence splitter based on punctuation
        let parts = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 2 }
    }
}
