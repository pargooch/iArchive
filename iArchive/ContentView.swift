import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @State private var selectedTab: Int = 0
    @State private var showGlobalCameraOptions = false
    // Lift selection state to align global bottom row actions (trash + camera)
    @State private var isSelecting = false
    @State private var selectedIndices: Set<Int> = []

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(isSelecting: $isSelecting, selectedIndices: $selectedIndices)
                    .tabItem { Label("Home", systemImage: "house") }
                    .tag(0)

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(1)
            }
            .tint(.brandPrimary)

            // Global bottom row: left trash (when selecting) and right camera
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    HStack {
                        // Left trash button appears only when selecting and items chosen
                        if isSelecting && !selectedIndices.isEmpty {
                            Button(action: deleteSelected) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandPrimary)
                                        .frame(width: 54, height: 54)
                                        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                                        .shadow(color: Color.white.opacity(0.6), radius: 3, x: 0, y: 0)
                                    Image(systemName: "trash")
                                        .foregroundColor(.white)
                                        .font(.system(size: 22, weight: .bold))
                                }
                            }
                        }
                        Spacer()
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
                    }
                    .padding(.bottom, 2)
                    .padding(.horizontal, 20)
                    .offset(y: 6)
                }
            }
        }
        .sheet(isPresented: $showGlobalCameraOptions) {
            CameraOptionsView()
                .environmentObject(library)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
        }
    }

    // Delete selected documents and exit selection mode
    private func deleteSelected() {
        let sorted = selectedIndices.sorted()
        guard !sorted.isEmpty else { return }
        library.deleteDocument(at: IndexSet(sorted))
        selectedIndices.removeAll()
        isSelecting = false
    }
}

struct HomeView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @State private var searchText = ""
    @State private var selectedDocument: PersistedDocument? = nil
    @Binding var isSelecting: Bool
    @Binding var selectedIndices: Set<Int>
    @State private var showCameraOptions = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Top bar: centered title, trailing controls layered
                    ZStack {
                        Text("Home")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
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

                    HStack {
                        SearchField(text: $searchText)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

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
                        .contentShape(Rectangle())
                        .onTapGesture { dismissKeyboard() }
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
                        .scrollDismissesKeyboard(.immediately)
                    }

                    // Bottom actions removed per request; actions will appear post-scan
                }
                // Trash button moved to global bottom row in ContentView
            }
            .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
            .navigationBarHidden(true)
            .tint(.brandPrimary)
        }
        .sheet(item: $selectedDocument) { doc in
            DocumentDetailView(document: doc)
                .environmentObject(library)
        }
        .sheet(isPresented: $showCameraOptions) {
            CameraOptionsView()
                .environmentObject(library)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
        }
    }

    // Export/Share/Save moved to post-scan actions

    // deleteSelected moved to ContentView

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

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            // Selection indicator on the far-left; no overlap with thumbnail
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .brandPrimary : .secondary)
                    .font(.system(size: 22, weight: .bold))
            }

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

            // Selection indicator moved behind-left of thumbnail
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

