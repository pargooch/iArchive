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

                    Text("iArchive helps you capture documents, organize pages, and export professional PDFs.")
                        .foregroundColor(.secondary)

                    Group {
                        Text("Getting Started").font(.headline)
                        Text("Use the plus button on the Home tab to add pages by scanning with your camera, picking from Photos, or importing from Files.")
                    }

                    Group {
                        Text("Scanning Documents").font(.headline)
                        Text("The camera scanner detects edges and enhances readability. After scanning, you can review pages and proceed to export or save.")
                    }

                    Group {
                        Text("Managing Documents").font(.headline)
                        Text("Each document shows its pages. You can rename documents, and quickly open them from the Home tab.")
                    }

                    Group {
                        Text("Exporting PDFs").font(.headline)
                        Text("Create a single PDF from all pages. After export, choose to share the PDF or save it to Files/iCloud Drive.")
                    }

                    Group {
                        Text("Saving to Photos").font(.headline)
                        Text("You can save the original images to your Photos library. Enable Photos access in Settings if prompted.")
                    }

                    Group {
                        Text("Files and iCloud Drive").font(.headline)
                        Text("If iCloud Drive is enabled, PDFs can be saved there directly. Otherwise, use the Files picker to choose a destination.")
                    }

                    Group {
                        Text("Privacy").font(.headline)
                        Text("All processing occurs on-device. iArchive does not transmit your documents or images.")
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