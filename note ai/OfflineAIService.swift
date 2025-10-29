//
//  OfflineAIService.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import Foundation

struct OfflineAIService: AIService {

    func answer(question: String, with contextSnippets: [ContextSnippet]) async throws -> String {
        let q = normalize(question)
        guard !q.isEmpty else { return "Please ask a question." }
        guard !contextSnippets.isEmpty else { return "I couldn't find anything relevant in your notes." }

        // Build a small corpus of sentences from the retrieved snippets
        let sentences = splitIntoSentences(contextSnippets.map { $0.text }.joined(separator: "\n"))
        if sentences.isEmpty {
            return "I couldn't find enough information in your notes to answer."
        }

        // Score sentences by relevance to the question
        let qTokens = tokenize(q)
        let scored = sentences.map { s -> (String, Double) in
            let sTokens = tokenize(s)
            let overlap = jaccard(qTokens, sTokens)
            let tfidfScore = tfidfLikeScore(query: qTokens, doc: sTokens)
            // Weighted combination
            let score = 0.6 * overlap + 0.4 * tfidfScore
            return (s, score)
        }
        .sorted { $0.1 > $1.1 }

        // Select top-K sentences and assemble an answer
        let top = scored.prefix(6).map { $0.0 }
        if top.isEmpty {
            return "I couldn't find enough information in your notes to answer."
        }

        // Optionally cluster/reduce redundancy (simple uniqueness filter)
        var uniqueSentences: [String] = []
        var seenHashes = Set<String>()
        for s in top {
            let h = fingerprint(s)
            if !seenHashes.contains(h) {
                uniqueSentences.append(s)
                seenHashes.insert(h)
            }
        }

        // Build a concise, grounded answer
        let summary = summarize(sentences: uniqueSentences, maxSentences: 4)

        // Provide simple citations by mapping sentences back to snippets
        let citations = buildCitations(for: uniqueSentences, in: contextSnippets)

        var parts: [String] = []
        parts.append(summary)
        if !citations.isEmpty {
            parts.append("\nSources:\n" + citations.map { "- \($0.title)" }.joined(separator: "\n"))
        }
        parts.append("\nNote: This answer was generated locally without the internet using extractive summarization of your notes.")

        return parts.joined(separator: "\n")
    }

    // MARK: - NLP Helpers (lightweight, fully offline)

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        // Very simple sentence splitter
        let raw = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        let parts = raw.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 2 }
    }

    private func jaccard(_ a: [String], _ b: [String]) -> Double {
        let sa = Set(a)
        let sb = Set(b)
        let inter = sa.intersection(sb).count
        let union = sa.union(sb).count
        if union == 0 { return 0 }
        return Double(inter) / Double(union)
    }

    private func tfidfLikeScore(query: [String], doc: [String]) -> Double {
        // Not true TF-IDF (we don't have a corpus), but weight rarer query tokens more
        let dSet = Set(doc)
        guard !dSet.isEmpty else { return 0 }
        var score = 0.0
        for token in query {
            if dSet.contains(token) {
                // weight by inverse token length as a crude proxy for rarity
                let w = 1.0 / max(2.0, Double(token.count))
                score += w
            }
        }
        return score
    }

    private func fingerprint(_ s: String) -> String {
        // Simple hash to avoid duplicates
        String(s.lowercased().prefix(8)) + String(s.hashValue)
    }

    private func summarize(sentences: [String], maxSentences: Int) -> String {
        let chosen = Array(sentences.prefix(maxSentences))
        if chosen.isEmpty { return "I couldn't find enough information in your notes to answer." }
        // Join and lightly clean
        let text = chosen.joined(separator: ". ") + "."
        return text
    }

    private func buildCitations(for sentences: [String], in snippets: [ContextSnippet]) -> [ContextSnippet] {
        // Map sentences back to the snippet whose text contains them the most
        var used = [UUID: ContextSnippet]()
        for s in sentences {
            var best: (ContextSnippet, Int)? = nil
            for snip in snippets {
                let count = occurrences(of: s, in: snip.text)
                if count > 0 {
                    if let b = best {
                        if count > b.1 { best = (snip, count) }
                    } else {
                        best = (snip, count)
                    }
                }
            }
            if let (snip, _) = best {
                used[snip.id] = snip
            }
        }
        return Array(used.values)
    }

    private func occurrences(of needle: String, in haystack: String) -> Int {
        if needle.isEmpty || haystack.isEmpty { return 0 }
        var count = 0
        var searchRange: Range<String.Index>? = haystack.startIndex..<haystack.endIndex
        while let range = haystack.range(of: needle, options: .caseInsensitive, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<haystack.endIndex
        }
        return count
    }
}
