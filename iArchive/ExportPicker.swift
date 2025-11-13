import SwiftUI
import UIKit

// ExportPicker presents the Files UI to export a local file (e.g., to iCloud Drive).
// Use on iOS 14+ with `UIDocumentPickerViewController(forExporting:)`.
struct ExportPicker: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url])
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}