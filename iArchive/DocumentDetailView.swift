import SwiftUI
import UIKit
import Photos

struct DocumentDetailView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @Environment(\.dismiss) private var dismiss

    let document: PersistedDocument

    @State private var showRename = false
    @State private var tempName: String = ""
    // Share sheet state for exporting PDF
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    // Alerts for save to Photos and PDF failures
    @State private var showSaveAlert = false
    @State private var saveSuccess = false
    @State private var showPDFFailureAlert = false
    @State private var showPDFSuccessAlert = false
    @State private var lastSavedPDFURL: URL? = nil
    @State private var showExportPicker = false
    @State private var showExportOptions = false
    @State private var photoAuthStatus: PHAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(library.images(for: document).enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 4)
                            .padding(.horizontal)
                    }

                    // Action buttons: Export PDF and Save to Photos
                    VStack(spacing: 12) {
                        Button(action: exportPDF) {
                            HStack { Image(systemName: "doc.richtext"); Text("Export PDF").fontWeight(.semibold) }
                        }
                        .primaryButton()

                        Button(action: saveImages) {
                            HStack { Image(systemName: "square.and.arrow.down"); Text("Save to Photos").fontWeight(.semibold) }
                        }
                        .primaryButton()
                        .disabled(photoAuthStatus == .denied || photoAuthStatus == .restricted)
                        
                        if photoAuthStatus == .denied || photoAuthStatus == .restricted {
                            Text("Photos permission required. Tap after enabling access.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Back") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Rename") { tempName = document.name; showRename = true } }
            }
            // Share sheet (kept available but not used for Export PDF now)
            .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
            // Alert reporting Photos save result.
            .alert(saveSuccess ? "Saved" : "Not Saved", isPresented: $showSaveAlert) {
                if !saveSuccess {
                    Button("Open Settings") { openSettings() }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveSuccess ? "Images saved to Photos." : "Enable Photos permission in Settings.")
            }
            // Alert for PDF generation failures.
            .alert("Failed to generate PDF", isPresented: $showPDFFailureAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again. If the issue persists, check storage.")
            }
            // Alert for PDF save success (Documents directory)
            .alert("PDF Saved", isPresented: $showPDFSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your PDF was saved to the app's Documents directory.\n\(lastSavedPDFURL?.lastPathComponent ?? "")")
            }
            // Files export UI (allows saving to iCloud Drive if direct save isn't available)
            .sheet(isPresented: $showExportPicker) {
                if let url = lastSavedPDFURL {
                    ExportPicker(url: url)
                }
            }
            // Choice UI similar to Genius app: Share or Save to Files
            .confirmationDialog("Export PDF", isPresented: $showExportOptions, titleVisibility: .visible) {
                if let url = lastSavedPDFURL {
                    Button("Share PDF") {
                        shareItems = [url]
                        showShare = true
                    }
                    Button("Save to Files") {
                        showExportPicker = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose how you want to export your PDF.")
            }
        }
        .tint(.brandPrimary)
        .onAppear { updatePhotoAuthStatus() }
        .sheet(isPresented: $showRename) {
            NavigationView {
                Form {
                    Section(header: Text("Document Name")) {
                        TextField("Enter name", text: $tempName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(false)
                    }
                }
                .navigationTitle("Rename")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { showRename = false } }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { saveName() }
                            .disabled(tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func saveName() {
        let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        library.renameDocument(id: document.id, to: trimmed)
        showRename = false
    }

    // Export all pages of this document as a single PDF.
    // Generate PDF to Documents, then present options to Share or Save to Files.
    private func exportPDF() {
        let images = library.images(for: document)
        guard !images.isEmpty else {
            print("[DocumentDetailView] Export PDF aborted: no images for document \(document.name)")
            showPDFFailureAlert = true
            return
        }
        if let url = PDFExporter.generatePDFToDocuments(from: images, suggestedName: document.name) {
            lastSavedPDFURL = url
            print("[DocumentDetailView] PDF generated at: \(url.path). Presenting export options.")
            showExportOptions = true
        } else {
            showPDFFailureAlert = true
        }
    }

    // Save all pages of this document to the Photos library
    private func saveImages() {
        let images = library.images(for: document)
        PhotoSaver.save(images: images) { success in
            saveSuccess = success
            showSaveAlert = true
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func updatePhotoAuthStatus() {
        if #available(iOS 14, *) {
            photoAuthStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            photoAuthStatus = PHPhotoLibrary.authorizationStatus()
        }
    }
}