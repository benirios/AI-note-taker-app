//
//  ContentView.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var selection: Note?
    @State private var showingAskAI = false

    var body: some View {
        NavigationSplitView {
            NotesListView(notes: notes, selection: $selection)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button {
                            showingAskAI = true
                        } label: {
                            Label("Ask AI", systemImage: "sparkles")
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            addNote()
                        } label: {
                            Label("New Note", systemImage: "plus")
                        }
                    }
                }
        } detail: {
            if let note = selection {
                NoteEditorView(note: note)
            } else {
                ContentPlaceholder()
            }
        }
        .sheet(isPresented: $showingAskAI) {
            AskAIView()
                .presentationDetents([.medium, .large])
        }
    }

    private func addNote() {
        let new = Note(title: "New Note", body: "")
        context.insert(new)
        try? context.save()
        selection = new
    }
}

private struct ContentPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Select or create a note")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}
