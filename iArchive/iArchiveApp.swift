//
//  iArchiveApp.swift
//  iArchive
//
//  Created by Novin dokht Elmi on 09/11/25.
//

import SwiftUI

@main
struct iArchiveApp: App {
    @StateObject private var library = DocumentLibrary()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
        }
    }
}
