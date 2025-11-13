import SwiftUI
import UIKit
import PDFKit

// MARK: - PDF Exporter (Persistent to Documents)
// Provides a single function to turn an array of UIImages into a PDF using PDFKit,
// and save the file into the app's Documents directory for persistence.
struct PDFExporter {
    // Temp PDF (UIGraphicsPDFRenderer), useful for quick sharing without persistence
    static func generatePDF(from images: [UIImage]) -> URL? {
        guard !images.isEmpty else {
            print("[PDFExporter] No images provided; aborting temp PDF generation")
            return nil
        }

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("scan_\(UUID().uuidString).pdf")

        do {
            try renderer.writePDF(to: tmp, withActions: { ctx in
                for image in images {
                    ctx.beginPage()
                    let aspect = min(pageRect.width / image.size.width, pageRect.height / image.size.height)
                    let drawSize = CGSize(width: image.size.width * aspect, height: image.size.height * aspect)
                    let drawRect = CGRect(
                        x: (pageRect.width - drawSize.width) / 2,
                        y: (pageRect.height - drawSize.height) / 2,
                        width: drawSize.width,
                        height: drawSize.height
                    )
                    image.draw(in: drawRect)
                }
            })
            print("[PDFExporter] Temp PDF written to: \(tmp.path)")
            return tmp
        } catch {
            print("[PDFExporter] Failed to write temp PDF: \(error)")
            return nil
        }
    }

    /// Generates a single PDF from the given images and writes it into the app's Documents directory.
    /// - Parameters:
    ///   - images: Array of `UIImage` pages to include in the PDF (order preserved).
    ///   - suggestedName: Optional base name used in the output filename. A timestamp is appended.
    /// - Returns: File URL of the created PDF in Documents on success; `nil` on failure.
    static func generatePDFToDocuments(from images: [UIImage], suggestedName: String? = nil) -> URL? {
        // Validate input
        guard !images.isEmpty else {
            print("[PDFExporter] No images provided; aborting persistent PDF generation")
            return nil
        }

        let pdfDocument = PDFDocument()
        for (index, image) in images.enumerated() {
            if let page = PDFPage(image: image) {
                pdfDocument.insert(page, at: index)
            } else {
                print("[PDFExporter] Skipped image at index \(index): could not create PDFPage")
            }
        }

        // Build a friendly, safe filename
        let baseName: String = {
            let name = (suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "scan")
            let safe = name.replacingOccurrences(of: "/", with: "_")
                           .replacingOccurrences(of: ":", with: "_")
                           .replacingOccurrences(of: "\n", with: " ")
            return safe.isEmpty ? "scan" : safe
        }()
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "\(baseName)-\(timestamp).pdf"

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filename)

        let success = pdfDocument.write(to: fileURL)
        if success {
            print("[PDFExporter] Persistent PDF written to Documents: \(fileURL.path)")
            return fileURL
        } else {
            print("[PDFExporter] Failed to write persistent PDF to: \(fileURL.path)")
            return nil
        }
    }

    /// Attempts to save the generated PDF directly into iCloud Drive (ubiquity container).
    /// Requires iCloud Documents capability enabled in the project.
    /// Falls back by returning nil if the ubiquity container is unavailable.
    static func generatePDFToICloudDrive(from images: [UIImage], suggestedName: String? = nil) -> URL? {
        guard !images.isEmpty else {
            print("[PDFExporter] No images provided; aborting iCloud PDF generation")
            return nil
        }

        // Check iCloud container availability
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            print("[PDFExporter] iCloud ubiquity container not available — ensure iCloud Documents capability is enabled")
            return nil
        }

        let pdfDocument = PDFDocument()
        for (index, image) in images.enumerated() {
            if let page = PDFPage(image: image) {
                pdfDocument.insert(page, at: index)
            } else {
                print("[PDFExporter] Skipped image at index \(index): could not create PDFPage")
            }
        }

        // iCloud Documents folder inside the ubiquity container
        let iCloudDocs = containerURL.appendingPathComponent("Documents")
        do { try FileManager.default.createDirectory(at: iCloudDocs, withIntermediateDirectories: true) } catch {
            print("[PDFExporter] Failed to create iCloud Documents directory: \(error)")
            return nil
        }

        let baseName: String = {
            let name = (suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "scan")
            let safe = name.replacingOccurrences(of: "/", with: "_")
                           .replacingOccurrences(of: ":", with: "_")
                           .replacingOccurrences(of: "\n", with: " ")
            return safe.isEmpty ? "scan" : safe
        }()
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "\(baseName)-\(timestamp).pdf"
        let fileURL = iCloudDocs.appendingPathComponent(filename)

        let success = pdfDocument.write(to: fileURL)
        if success {
            print("[PDFExporter] Persistent PDF written to iCloud Drive: \(fileURL.path)")
            return fileURL
        } else {
            print("[PDFExporter] Failed to write PDF to iCloud Drive: \(fileURL.path)")
            return nil
        }
    }
}

struct DocumentPreviewView: View {
    @State var scannedImages: [UIImage] // Your scanned/imported images

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(scannedImages.indices, id: \.self) { index in
                        Image(uiImage: scannedImages[index])
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 200)
                            .cornerRadius(8)
                            .padding(4)
                    }
                }
            }

            Button(action: exportPDF) {
                Label("Export PDF", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Preview")
    }

    // MARK: - Export PDF Function
    func exportPDF() {
        guard !scannedImages.isEmpty else {
            print("⚠️ No images to export.")
            return
        }

        // Generate PDF in Documents directory
        if let pdfURL = PDFExporter.generatePDFToDocuments(from: scannedImages, suggestedName: "MyScan") {
            print("✅ PDF saved at: \(pdfURL.path)")
            sharePDF(at: pdfURL)
        } else {
            print("❌ Failed to generate PDF")
        }
    }

    // MARK: - Share Sheet
    func sharePDF(at url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        // Get root view controller safely
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        } else {
            print("⚠️ Could not find root view controller to present share sheet.")
        }
    }
}