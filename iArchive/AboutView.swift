import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About iArchive")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("iArchive is a lightweight document scanner and PDF exporter designed to make capturing, organizing, and sharing documents effortless.")
                        .foregroundColor(.secondary)

                    Group {
                        Text("Origin").font(.headline)
                        Text("iArchive was developed in Napoli as a practice project at the Apple Developer Academy by Novin Dokht Elmi.")
                    }

                    Group {
                        Text("Purpose").font(.headline)
                        Text("The app focuses on a clear workflow: scan or import pages, preview results, and export professional PDFs or save images to Photos.")
                    }

                    Group {
                        Text("Technology").font(.headline)
                        Text("iArchive uses a focused, on-device stack to deliver a fast and private experience:")
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• SwiftUI for the user interface and navigation.")
                            Text("• Combine (@Published/ObservableObject) for reactive state management.")
                            Text("• PDFKit to compose multi-page PDFs from images.")
                            Text("• VisionKit (VNDocumentCameraViewController) for camera-based document scanning.")
                            Text("• Vision framework to assist with document detection overlays.")
                            Text("• UIKit bridges (UIViewControllerRepresentable) for Share and Files pickers.")
                            Text("• Photos framework to save images to the Photos library.")
                            Text("• Files and iCloud Drive integration via UIDocumentPicker and ubiquity container when available.")
                            Text("• Foundation APIs for secure, local file storage in the app’s Documents directory.")
                        }
                    }

                    Group {
                        Text("Acknowledgements").font(.headline)
                        Text("This project reflects best practices learned at the Apple Developer Academy and the vibrant developer community in Napoli.")
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() } }
            }
        }
        .tint(.brandPrimary)
    }
}