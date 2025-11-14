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
                        .foregroundColor(Color(hex: "#643cb6"))

                    HighlightedText(
                        text: "iArchive is a lightweight document scanner and PDF exporter designed to make capturing, organizing, and sharing documents effortless.",
                        keywords: ["iArchive", "scanner", "PDF", "capturing", "organizing", "sharing", "documents"]
                    )
                    .foregroundColor(.secondary)

                    Group {
                        Text("Origin").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "iArchive was developed in Napoli as a practice project at the Apple Developer Academy by Novin Dokht Elmi.",
                            keywords: ["iArchive", "Napoli", "Apple Developer Academy"]
                        )
                    }

                    Group {
                        Text("Purpose").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "The app focuses on a clear workflow: scan or import pages, preview results, and export professional PDFs or save images to Photos.",
                            keywords: ["scan", "import", "pages", "export", "PDFs", "Photos"]
                        )
                    }

                    Group {
                        Text("Technology").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        Text("iArchive uses a focused, on-device stack to deliver a fast and private experience:")
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 8) {
                            HighlightedText(text: "• SwiftUI for the user interface and navigation.", keywords: ["SwiftUI"])
                            HighlightedText(text: "• Combine (@Published/ObservableObject) for reactive state management.", keywords: ["Combine", "@Published", "ObservableObject"])
                            HighlightedText(text: "• PDFKit to compose multi-page PDFs from images.", keywords: ["PDFKit", "PDFs"])
                            HighlightedText(text: "• VisionKit (VNDocumentCameraViewController) for camera-based document scanning.", keywords: ["VisionKit", "VNDocumentCameraViewController"])
                            HighlightedText(text: "• Vision framework to assist with document detection overlays.", keywords: ["Vision"])
                            HighlightedText(text: "• UIKit bridges (UIViewControllerRepresentable) for Share and Files pickers.", keywords: ["UIKit", "UIViewControllerRepresentable", "Files"])
                            HighlightedText(text: "• Photos framework to save images to the Photos library.", keywords: ["Photos"])
                            HighlightedText(text: "• Files and iCloud Drive integration via UIDocumentPicker and ubiquity container when available.", keywords: ["Files", "iCloud Drive", "UIDocumentPicker"])
                            HighlightedText(text: "• Foundation APIs for secure, local file storage in the app’s Documents directory.", keywords: ["Foundation", "Documents"])
                        }
                    }

                    Group {
                        Text("Acknowledgements").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "This project reflects best practices learned at the Apple Developer Academy and the vibrant developer community in Napoli.",
                            keywords: ["Apple Developer Academy", "Napoli"]
                        )
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

// MARK: - Highlight helper for coloring keywords
private struct HighlightedText: View {
    let text: String
    let keywords: [String]

    var body: some View {
        composedText(text: text, keywords: keywords)
    }

    private func composedText(text: String, keywords: [String]) -> Text {
        let parts = text.split(separator: " ", omittingEmptySubsequences: false)
        var result = Text("")
        for (i, part) in parts.enumerated() {
            let trimmed = part.trimmingCharacters(in: .punctuationCharacters)
            let match = keywords.contains { $0.caseInsensitiveCompare(String(trimmed)) == .orderedSame }
            let chunk = Text(String(part)).foregroundColor(match ? Color(hex: "#643cb6") : .primary)
            result = i == 0 ? chunk : result + Text(" ") + chunk
        }
        return result
    }
}