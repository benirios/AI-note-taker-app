//
//  note_aiApp.swift
//  note ai
//
//  Created by Benício Rios on 29/10/2025.
//

import SwiftUI
import SwiftData

@main
struct note_aiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Note.self)
    }
}
