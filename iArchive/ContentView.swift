import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @State private var showCameraOptions = false
    @State private var searchActive = false
    @State private var searchText = ""
    @State private var showDetail = false
    @State private var detailIndex: Int? = nil
    @State private var isSelecting = false
    @State private var selectedIndices: Set<Int> = []

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
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
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    Divider()

                    if searchActive {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                            TextField("Search documents", text: $searchText)
                                .textFieldStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // Content grid
                    ScrollView {
                        let columns = [GridItem(.flexible()), GridItem(.flexible())]
                        let indices = Array(library.documents.indices).filter { idx in
                            let name = library.documents[idx].name
                            return searchText.isEmpty ? true : name.localizedCaseInsensitiveContains(searchText)
                        }
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(indices, id: \.self) { index in
                                let isSelected = selectedIndices.contains(index)
                                Button(action: {
                                    if isSelecting {
                                        if isSelected { selectedIndices.remove(index) } else { selectedIndices.insert(index) }
                                    } else {
                                        detailIndex = index
                                        showDetail = true
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let thumb = library.thumbnail(for: library.documents[index]) {
                                            Image(uiImage: thumb)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 160)
                                                .cornerRadius(10)
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                                .overlay(alignment: .topTrailing) {
                                                    if isSelecting {
                                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                            .foregroundColor(isSelected ? .accentColor : .secondary)
                                                            .padding(6)
                                                    }
                                                }
                                        } else {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.systemGray5))
                                                    .frame(height: 160)
                                                Image(systemName: "doc")
                                                    .foregroundColor(.secondary)
                                            }
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            .overlay(alignment: .topTrailing) {
                                                if isSelecting {
                                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                        .foregroundColor(isSelected ? .accentColor : .secondary)
                                                        .padding(6)
                                                }
                                            }
                                        }
                                        Text(library.documents[index].name)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }

                    // Bottom actions removed per request; actions will appear post-scan
                }
                bottomActionButton
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showDetail) {
            if let idx = detailIndex, library.documents.indices.contains(idx) {
                DocumentDetailView(document: library.documents[idx])
                    .environmentObject(library)
            }
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
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
            } else {
                Button(action: { showCameraOptions = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.bottom, 24)
    }

    private func deleteSelected() {
        let sorted = selectedIndices.sorted()
        guard !sorted.isEmpty else { return }
        library.deleteDocument(at: IndexSet(sorted))
        selectedIndices.removeAll()
        isSelecting = false
    }
}

private struct RoundedButton: View {
    var icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .cornerRadius(16)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @State private var showClearAlert = false
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Library")) {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("Clear All Documents", systemImage: "trash")
                    }
                }
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Documents?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { library.clearAll() }
            }
        }
    }
}

