//
//  AskAIView.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import SwiftUI
import SwiftData

struct AskAIView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var isLoading: Bool = false
    @State private var usedSnippets: [ContextSnippet] = []

    private let retriever = RetrievalService()
    // Swap to OfflineAIService (fully offline)
    private let ai: AIService = OfflineAIService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("Ask a question about your notes…", text: $question, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                HStack {
                    Spacer()
                    Button {
                        Task { await ask() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Ask", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .padding(.horizontal)
                }

                if !answer.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(answer)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !usedSnippets.isEmpty {
                                Divider()
                                Text("Sources")
                                    .font(.headline)
                                ForEach(usedSnippets) { s in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(s.title).font(.subheadline).bold()
                                        Text(s.text).font(.footnote).foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                }
            }
            .navigationTitle("Ask AI")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func ask() async {
        isLoading = true
        defer { isLoading = false }
        let snippets = retriever.retrieveRelevantNotes(question: question, from: notes)
        usedSnippets = snippets
        do {
            answer = try await ai.answer(question: question, with: snippets)
        } catch {
            answer = "Failed to get answer: \(error.localizedDescription)"
        }
    }
}
