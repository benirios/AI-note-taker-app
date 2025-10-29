//
//  NotesListView.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import SwiftUI
import SwiftData

struct NotesListView: View {
    let notes: [Note]
    @Binding var selection: Note?

    @State private var searchText: String = ""

    var filteredNotes: [Note] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return notes }
        let q = searchText.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q) || $0.tags.joined(separator: " ").lowercased().contains(q)
        }
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(filteredNotes) { note in
                NavigationLink(value: note) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title.isEmpty ? "Untitled" : note.title)
                            .font(.headline)
                        if !note.body.isEmpty {
                            Text(note.body)
                                .font(.subheadline)
                                .lineLimit(2)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            ForEach(note.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        }
                    }
                }
                .tag(note)
            }
        }
        .searchable(text: $searchText, placement: .sidebar)
        .navigationTitle("Notes")
    }
}
