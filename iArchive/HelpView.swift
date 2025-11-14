import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welcome to iArchive")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#643cb6"))

                    HighlightedText(
                        text: "iArchive helps you capture documents, organize pages, and export professional PDFs.",
                        keywords: ["iArchive", "capture", "documents", "pages", "PDFs"]
                    )
                    .foregroundColor(.secondary)

                    Group {
                        Text("Getting Started").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "Use the plus button on the Home tab to add pages by scanning with your camera, picking from Photos, or importing from Files.",
                            keywords: ["plus", "Home", "pages", "scanning", "Photos", "Files"]
                        )
                    }

                    Group {
                        Text("Scanning Documents").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "The camera scanner detects edges and enhances readability. After scanning, you can review pages and proceed to export or save.",
                            keywords: ["scanner", "edges", "scanning", "export", "save"]
                        )
                    }

                    Group {
                        Text("Managing Documents").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "Each document shows its pages. You can rename documents, and quickly open them from the Home tab.",
                            keywords: ["document", "pages", "rename", "Home"]
                        )
                    }

                    Group {
                        Text("Exporting PDFs").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "Create a single PDF from all pages. After export, choose to share the PDF or save it to Files/iCloud Drive.",
                            keywords: ["PDF", "export", "share", "Files", "iCloud Drive"]
                        )
                    }

                    Group {
                        Text("Saving to Photos").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "You can save the original images to your Photos library. Enable Photos access in Settings if prompted.",
                            keywords: ["Photos", "save", "library", "Settings"]
                        )
                    }

                    Group {
                        Text("Files and iCloud Drive").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "If iCloud Drive is enabled, PDFs can be saved there directly. Otherwise, use the Files picker to choose a destination.",
                            keywords: ["iCloud Drive", "PDFs", "Files", "picker"]
                        )
                    }

                    Group {
                        Text("Privacy").font(.headline).foregroundColor(Color(hex: "#643cb6"))
                        HighlightedText(
                            text: "All processing occurs on-device. iArchive does not transmit your documents or images.",
                            keywords: ["on-device", "iArchive", "documents", "images"]
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Help")
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
            let chunk = Text(String(part)).foregroundColor(match ? Color(hex: "#643cb6") : .secondary)
            result = i == 0 ? chunk : result + Text(" ") + chunk
        }
        return result
    }
}