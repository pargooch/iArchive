import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @State private var showGlobalCameraOptions = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .tint(.brandPrimary)

            // Floating camera button positioned at the bottom-left of the page
            VStack {
                Spacer()
                HStack {
                    Button(action: { showGlobalCameraOptions = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.brandPrimary)
                                .frame(width: 54, height: 54)
                                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                                .shadow(color: Color.white.opacity(0.6), radius: 3, x: 0, y: 0) // subtle halo
                            CameraPlusIcon()
                        }
                    }
                    .accessibilityLabel("Scan with Camera")
                    Spacer()
                }
                .padding(.bottom, 34)
                .padding(.leading, 20)
                .offset(y: -8)
            }
        }
        .fullScreenCover(isPresented: $showGlobalCameraOptions) {
            CameraOptionsView()
                .environmentObject(library)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @State private var showCameraOptions = false
    @State private var searchActive = false
    @State private var searchText = ""
    @State private var selectedDocument: PersistedDocument? = nil
    @State private var isSelecting = false
    @State private var selectedIndices: Set<Int> = []

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Top bar: centered title, trailing controls layered
                    ZStack {
                        Text("Documents")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                RoundedButton(icon: "magnifyingglass") { searchActive.toggle() }
                                RoundedButton(icon: isSelecting ? "xmark" : "checkmark.circle") {
                                    if isSelecting {
                                        isSelecting = false
                                        selectedIndices.removeAll()
                                    } else {
                                        isSelecting = true
                                    }
                                }
                                if isSelecting {
                                    RoundedButton(icon: allSelected ? "checkmark.square.fill" : "checkmark.square") {
                                        toggleSelectAll()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    Divider()

                    if searchActive {
                        HStack(spacing: 8) {
                            SearchField(text: $searchText)
                            Button("Cancel") {
                                searchText = ""
                                withAnimation { searchActive = false }
                            }
                            .foregroundColor(.brandPrimary)
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Professional list or empty state
                    if library.documents.isEmpty {
                        ZStack {
                            Color(.systemGroupedBackground)
                                .ignoresSafeArea()

                            VStack(spacing: 12) {
                                Image(systemName: "doc")
                                    .font(.system(size: 56))
                                    .foregroundColor(.secondary)
                                Text("You haven't scanned any document")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Tap the + button to add your first document.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 240)
                            .padding(.top, 32)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        let indices = Array(library.documents.indices).filter { idx in
                            let name = library.documents[idx].name
                            return searchText.isEmpty ? true : name.localizedCaseInsensitiveContains(searchText)
                        }
                        List {
                            ForEach(indices, id: \.self) { index in
                                let doc = library.documents[index]
                                let isSelected = selectedIndices.contains(index)
                                Button(action: {
                                    if isSelecting {
                                        if isSelected { selectedIndices.remove(index) } else { selectedIndices.insert(index) }
                                    } else {
                                        selectedDocument = doc
                                    }
                                }) {
                                    DocumentRow(
                                        document: doc,
                                        thumbnail: library.thumbnail(for: doc),
                                        isSelecting: isSelecting,
                                        isSelected: isSelected
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .listStyle(.insetGrouped)
                    }

                    // Bottom actions removed per request; actions will appear post-scan
                }
                bottomActionButton
            }
            .navigationBarHidden(true)
            .tint(.brandPrimary)
        }
        .sheet(item: $selectedDocument) { doc in
            DocumentDetailView(document: doc)
                .environmentObject(library)
        }
        .fullScreenCover(isPresented: $showCameraOptions) {
            CameraOptionsView()
                .environmentObject(library)
        }
    }

    // Export/Share/Save moved to post-scan actions

    @ViewBuilder
    private var bottomActionButton: some View {
        Group {
            if isSelecting {
                if !selectedIndices.isEmpty {
                    Button(action: deleteSelected) {
                        Image(systemName: "trash")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.brandPrimary)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 24)
    }

    private func deleteSelected() {
        let sorted = selectedIndices.sorted()
        guard !sorted.isEmpty else { return }
        library.deleteDocument(at: IndexSet(sorted))
        selectedIndices.removeAll()
        isSelecting = false
    }

    private var allSelected: Bool {
        !library.documents.isEmpty && selectedIndices.count == library.documents.count
    }

    private func toggleSelectAll() {
        if allSelected {
            selectedIndices.removeAll()
        } else {
            selectedIndices = Set(library.documents.indices)
        }
    }
}

private struct RoundedButton: View {
    var icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.brandPrimary)
                .frame(width: 32, height: 32)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.brandPrimary.opacity(0.6), lineWidth: 1)
                )
                .cornerRadius(16)
        }
    }
}

private struct CameraPlusIcon: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "camera.fill")
                .foregroundColor(.white)
                .font(.system(size: 26, weight: .bold))
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                Image(systemName: "plus")
                    .foregroundColor(.brandPrimary)
                    .font(.system(size: 10, weight: .bold))
            }
            .offset(x: 6, y: 5)
        }
    }
}

// (Reverted) Removed the custom SearchBar component to restore
// the previous inline search UI.

private struct DocumentRow: View {
    let document: PersistedDocument
    let thumbnail: UIImage?
    let isSelecting: Bool
    let isSelected: Bool

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or placeholder
            if let thumb = thumbnail {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipped()
                    .cornerRadius(8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)
                    Image(systemName: "doc")
                        .foregroundColor(.secondary)
                }
            }

            // Title and metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                let pages = document.pagePaths.count
                let dateText = Self.dateFormatter.string(from: document.date)
                Text("\(pages) page\(pages == 1 ? "" : "s") • \(dateText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Selection indicator when selecting
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .brandPrimary : .secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @State private var showHelp = false
    @State private var showAbout = false
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Support")) {
                    Button {
                        showHelp = true
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                }
                Section(header: Text("Information")) {
                    Button {
                        showAbout = true
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .tint(.brandPrimary)
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}
// Removed ScanTabTriggerView; center button now overlays the TabView to sit above it.

// MARK: - Search Field Component
private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search documents", text: $text)
                .textFieldStyle(.plain)
                .submitLabel(.done)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

