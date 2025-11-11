import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ScanTabView()
                .tabItem {
                    Label("Scan", systemImage: "doc.viewfinder")
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

    var body: some View {
        NavigationView {
            VStack {
                if store.pages.isEmpty {
                    Text("No pages yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(Array(store.pages.indices), id: \.self) { index in
                            HStack {
                                Image(uiImage: store.pages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .cornerRadius(8)
                                Text("Page \(index + 1)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: store.remove)
                        .onMove(perform: store.move)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: exportPDF) {
                        Label("Export PDF", systemImage: "doc.richtext")
                    }
                    .disabled(store.pages.isEmpty)

                    Button(action: exportImages) {
                        Label("Share Images", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.pages.isEmpty)

                    Button(action: saveImages) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                    .disabled(store.pages.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Library")
            .toolbar { EditButton() }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text(saveSuccess ? "Saved" : "Not Saved"),
                message: Text(saveSuccess ? "Images saved to Photos." : "Enable Photos permission in Settings."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func exportPDF() {
        guard let url = PDFExporter.generatePDF(from: store.pages) else { return }
        shareItems = [url]
        showShare = true
    }

    private func exportImages() {
        shareItems = store.pages
        showShare = true
    }

    private func saveImages() {
        PhotoSaver.save(images: store.pages) { success in
            saveSuccess = success
            showSaveAlert = true
        }
    }
}

struct ScanTabView: View {
    @EnvironmentObject private var store: ScannedPagesStore
    @State private var showScanner = false

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
            DocumentScannerView(images: $store.pages) {
                showScanner = false
            }
        }
    }
}

