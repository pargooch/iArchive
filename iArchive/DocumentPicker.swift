import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct DocumentPicker: UIViewControllerRepresentable {
    var onComplete: ([UIImage]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.image, .pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onComplete: ([UIImage]) -> Void
        init(onComplete: @escaping ([UIImage]) -> Void) { self.onComplete = onComplete }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var images: [UIImage] = []
            for url in urls {
                let _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }

                if url.pathExtension.lowercased() == "pdf" {
                    if let doc = PDFDocument(url: url) {
                        for i in 0..<doc.pageCount {
                            if let page = doc.page(at: i) {
                                let size = CGSize(width: 1000, height: 1414) // ~A4 proportion
                                let thumb = page.thumbnail(of: size, for: .mediaBox)
                                images.append(thumb)
                            }
                        }
                    }
                } else {
                    if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                        images.append(img)
                    }
                }
            }
            controller.dismiss(animated: true) {
                self.onComplete(images)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true) {
                self.onComplete([])
            }
        }
    }
}