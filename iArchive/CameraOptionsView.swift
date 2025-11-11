import SwiftUI

struct CameraOptionsView: View {
    @EnvironmentObject private var store: ScannedPagesStore
    @Environment(\.dismiss) private var dismiss

    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var postScanImages: [UIImage] = []
    @State private var showPostActions = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()

                VStack(spacing: 24) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    Spacer()

                    VStack(spacing: 16) {
                        Button(action: { showPhotoPicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Add from Gallery")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: { showScanner = true }) {
                            HStack {
                                Image(systemName: "doc.viewfinder")
                                Text("Scan with Camera")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: { showDocumentPicker = true }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Choose from Files")
                                    .fontWeight(.semibold)
                            }
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
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView(
                images: $store.pages,
                onDismiss: { showScanner = false },
                onCompleted: { imgs in
                    postScanImages = imgs
                    showPostActions = true
                }
            )
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { images in
                store.add(images: images)
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { images in
                store.add(images: images)
            }
        }
        .sheet(isPresented: $showPostActions) {
            PostScanActionsView(images: postScanImages)
                .environmentObject(store)
        }
    }

    // No flashlight toggle on this page per request
}