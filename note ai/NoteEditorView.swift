//
//  NoteEditorView.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.modelContext) private var context
    @State var note: Note

    @State private var tagsText: String = ""

    var body: some View {
        Form {
            TextField("Title", text: $note.title)
                .font(.title2)
            TextEditor(text: $note.body)
                .frame(minHeight: 240)
            Section("Tags (comma-separated)") {
                TextField("e.g. work, research", text: $tagsText)
                    .onAppear {
                        tagsText = note.tags.joined(separator: ", ")
                    }
                    .onChange(of: tagsText) { _, newValue in
                        note.tags = newValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    }
            }
            Section {
                HStack {
                    Label("Created", systemImage: "calendar")
                    Spacer()
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("Updated", systemImage: "clock")
                    Spacer()
                    Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .navigationTitle(note.title.isEmpty ? "Untitled" : note.title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    deleteNote()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    saveNote()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
            }
        }
        .onChange(of: note.title) { _, _ in touch() }
        .onChange(of: note.body) { _, _ in touch() }
        .onChange(of: note.tags) { _, _ in touch() }
    }

    private func touch() {
        note.updatedAt = .now
    }

    private func saveNote() {
        context.insert(note)
        try? context.save()
    }

    private func deleteNote() {
        context.delete(note)
        try? context.save()
    }
}
