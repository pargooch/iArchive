import SwiftUI

struct PostScanActionsView: View {
    @EnvironmentObject private var store: ScannedPagesStore
    @Environment(\.dismiss) private var dismiss

    let images: [UIImage]
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    @State private var showSaveAlert = false
    @State private var saveSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Actions for \(images.count) scanned page\(images.count == 1 ? "" : "s")")
                    .font(.headline)
                    .padding(.top)

                if let first = images.first {
                    Image(uiImage: first)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    Button(action: exportPDF) {
                        HStack { Image(systemName: "doc.richtext"); Text("Export PDF").fontWeight(.semibold) }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: shareImages) {
                        HStack { Image(systemName: "square.and.arrow.up"); Text("Share Images").fontWeight(.semibold) }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: saveImages) {
                        HStack { Image(systemName: "square.and.arrow.down"); Text("Save to Photos").fontWeight(.semibold) }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Post Scan")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() } }
            }
        }
        .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text(saveSuccess ? "Saved" : "Not Saved"),
                message: Text(saveSuccess ? "Images saved to Photos." : "Enable Photos permission in Settings."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func exportPDF() {
        guard let url = PDFExporter.generatePDF(from: images) else { return }
        shareItems = [url]
        showShare = true
    }

    private func shareImages() {
        shareItems = images
        showShare = true
    }

    private func saveImages() {
        PhotoSaver.save(images: images) { success in
            saveSuccess = success
            showSaveAlert = true
        }
    }
}