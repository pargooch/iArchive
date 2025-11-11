import UIKit
import PDFKit

struct PDFExporter {
    static func generatePDF(from images: [UIImage]) -> URL? {
        guard !images.isEmpty else { return nil }

        let pdfDocument = PDFDocument()
        for (index, image) in images.enumerated() {
            guard let page = PDFPage(image: image) else { continue }
            pdfDocument.insert(page, at: index)
        }
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("scan_\(UUID().uuidString).pdf")
        if pdfDocument.write(to: tmp) {
            return tmp
        }
        return nil
    }
}
