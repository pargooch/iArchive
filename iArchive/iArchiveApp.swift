//
//  iArchiveApp.swift
//  iArchive
//
//  Created by Novin dokht Elmi on 09/11/25.
//

import SwiftUI

@main
struct iArchiveApp: App {
    @StateObject private var store = ScannedPagesStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
