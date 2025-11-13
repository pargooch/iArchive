import SwiftUI

// Post-scan actions: export PDF, share images, or save to Photos.
// - Export PDF: generate a single PDF using PDFKit and present the share sheet.
// - Share Images: present the share sheet with the raw images.
// - Save to Photos: write images to the user's Photos library and show an alert on completion.
struct PostScanActionsView: View {
    @Environment(\.dismiss) private var dismiss

    // The images captured or imported in the previous step.
    let images: [UIImage]

    // Share sheet state: items can be a URL (PDF) or UIImages.
    @State private var showShare = false
    @State private var shareItems: [Any] = []

    // Save feedback alert.
    @State private var showSaveAlert = false
    @State private var saveSuccess = false

    // PDF generation failure alert.
    @State private var showPDFFailureAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Simple header showing count of pages.
                Text("Actions for \(images.count) scanned page\(images.count == 1 ? "" : "s")")
                    .font(.headline)
                    .padding(.top)

                // Thumbnail preview of the first image.
                if let first = images.first {
                    Image(uiImage: first)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.horizontal)
                }

                // Action buttons.
                VStack(spacing: 16) {
                    // Export images into a single PDF, then share.
                    Button(action: exportPDF) {
                        HStack { Image(systemName: "doc.richtext"); Text("Export PDF").fontWeight(.semibold) }
                    }
                    .primaryButton()

                    // Share original images using the share sheet.
                    Button(action: shareImages) {
                        HStack { Image(systemName: "square.and.arrow.up"); Text("Share Images").fontWeight(.semibold) }
                    }
                    .primaryButton()

                    // Save images into the user's Photos library.
                    Button(action: saveImages) {
                        HStack { Image(systemName: "square.and.arrow.down"); Text("Save to Photos").fontWeight(.semibold) }
                    }
                    .primaryButton()
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Post Scan")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() } }
            }
        }
        .tint(.brandPrimary)
        // Share sheet presentation with either PDF URL or images.
        .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
        // Simple alert reporting Photos save result.
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text(saveSuccess ? "Saved" : "Not Saved"),
                message: Text(saveSuccess ? "Images saved to Photos." : "Enable Photos permission in Settings."),
                dismissButton: .default(Text("OK"))
            )
        }
        // Alert for PDF generation failures.
        .alert("Failed to generate PDF", isPresented: $showPDFFailureAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again. If the issue persists, check permissions and storage.")
        }
    }

    // Combine all images into a single PDF and present the share sheet.
    private func exportPDF() {
        guard let url = PDFExporter.generatePDF(from: images) else {
            showPDFFailureAlert = true
            return
        }
        shareItems = [url]
        showShare = true
    }

    // Share raw images using the share sheet.
    private func shareImages() {
        shareItems = images
        showShare = true
    }

    // Save images to the Photos library and show a confirmation alert.
    private func saveImages() {
        PhotoSaver.save(images: images) { success in
            // Update UI state on completion.
            saveSuccess = success
            showSaveAlert = true
        }
    }
}