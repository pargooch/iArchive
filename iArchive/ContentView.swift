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
    @EnvironmentObject private var store: ScannedPagesStore
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    @State private var showSaveAlert = false
    @State private var saveSuccess = false
    @State private var showCameraOptions = false
    @State private var searchActive = false
    @State private var searchText = ""
    @State private var showDetail = false
    @State private var detailIndex: Int? = nil

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                VStack(spacing: 0) {
                    // Custom top bar like screenshot
                    HStack {
                        Spacer()
                        Text("Documents")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        RoundedButton(icon: "magnifyingglass") { searchActive.toggle() }
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
                        let indices = Array(store.pages.indices).filter { idx in
                            searchText.isEmpty ? true : (store.names.indices.contains(idx) && store.names[idx].localizedCaseInsensitiveContains(searchText))
                        }
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(indices, id: \.self) { index in
                                Button(action: {
                                    detailIndex = index
                                    showDetail = true
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Image(uiImage: store.pages[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 160)
                                            .cornerRadius(10)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        Text(store.names.indices.contains(index) ? store.names[index] : "Document \(index + 1)")
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
                addFloatingButton
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showDetail) {
            if let idx = detailIndex, store.pages.indices.contains(idx) {
                DocumentDetailView(image: store.pages[idx], name: store.names.indices.contains(idx) ? store.names[idx] : nil)
            }
        }
        .fullScreenCover(isPresented: $showCameraOptions) {
            CameraOptionsView()
                .environmentObject(store)
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text(saveSuccess ? "Saved" : "Not Saved"),
                message: Text(saveSuccess ? "Images saved to Photos." : "Enable Photos permission in Settings."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // Export/Share/Save moved to post-scan actions

    @ViewBuilder
    private var addFloatingButton: some View {
        Button(action: { showCameraOptions = true }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.orange)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .padding(.leading, 16)
        .padding(.bottom, 24)
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

struct ScanTabView: View {
    @EnvironmentObject private var store: ScannedPagesStore
    @State private var showScanner = false
    @State private var postScanImages: [UIImage] = []
    @State private var showPostActions = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)

                Text("Scan new documents with auto-crop and perspective correction.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Button(action: { showScanner = true }) {
                    Text("Start Scan")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                if !store.pages.isEmpty {
                    Text("Total pages: \(store.pages.count)")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Scan")
        }
        .sheet(isPresented: $showScanner) {
            DocumentScannerView(
                images: $store.pages,
                onDismiss: { showScanner = false },
                onCompleted: { imgs in
                    postScanImages = imgs
                    showPostActions = true
                }
            )
        }
        .sheet(isPresented: $showPostActions) {
            PostScanActionsView(images: postScanImages)
                .environmentObject(store)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: ScannedPagesStore
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
                Button("Clear", role: .destructive) { store.clear() }
            }
        }
    }
}

