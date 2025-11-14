import SwiftUI

struct CameraOptionsView: View {
    @EnvironmentObject private var library: DocumentLibrary
    @Environment(\.dismiss) private var dismiss

    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var postScanImages: [UIImage] = []
    @State private var showPostActions = false
    @State private var scannedTemp: [UIImage] = []

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Button(action: { showPhotoPicker = true }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Add from Gallery")
                            .fontWeight(.semibold)
                    }
                }
                .primaryButton()

                Button(action: { showScanner = true }) {
                    HStack {
                        Image(systemName: "doc.viewfinder")
                        Text("Scan with Camera")
                            .fontWeight(.semibold)
                    }
                }
                .primaryButton()

                Button(action: { showDocumentPicker = true }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Choose from Files")
                            .fontWeight(.semibold)
                    }
                }
                .primaryButton()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(
                images: $scannedTemp,
                onDismiss: { showScanner = false },
                onCompleted: { imgs in
                    library.addDocument(images: imgs)
                    postScanImages = imgs
                    showPostActions = true
                }
            )
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { images in
                library.addDocument(images: images)
            }
            .tint(.brandPrimary)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { images in
                library.addDocument(images: images)
            }
        }
        .sheet(isPresented: $showPostActions) {
            PostScanActionsView(images: postScanImages)
        }
    }

    // No flashlight toggle on this page per request
}