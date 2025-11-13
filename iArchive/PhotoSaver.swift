import UIKit
import Photos

// PhotoSaver saves UIImages to the user's Photos library.
// It requests authorization (needed for saving) and writes each image
// using UIImageWriteToSavedPhotosAlbum, tracking success across all images.
struct PhotoSaver {
    static func save(images: [UIImage], completion: @escaping (Bool) -> Void) {
        // Guard against empty input.
        guard !images.isEmpty else { completion(false); return }

        // Request permission to add items to Photos.
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }

                // Helper to collect per-image completion callbacks.
                let helper = SaveHelper(total: images.count) { allSucceeded in
                    completion(allSucceeded)
                }

                // Write must be performed on the main thread.
                DispatchQueue.main.async {
                    for image in images {
                        UIImageWriteToSavedPhotosAlbum(image, helper, #selector(SaveHelper.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }

                // Helper to collect per-image completion callbacks.
                let helper = SaveHelper(total: images.count) { allSucceeded in
                    completion(allSucceeded)
                }

                // Write must be performed on the main thread.
                DispatchQueue.main.async {
                    for image in images {
                        UIImageWriteToSavedPhotosAlbum(image, helper, #selector(SaveHelper.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                }
            }
        }
    }

    // Objective-C helper to receive callbacks from UIImageWriteToSavedPhotosAlbum.
    private class SaveHelper: NSObject {
        private let total: Int
        private var completed: Int = 0
        private var allSucceeded: Bool = true
        private let completion: (Bool) -> Void

        init(total: Int, completion: @escaping (Bool) -> Void) {
            self.total = total
            self.completion = completion
        }

        @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
            if error != nil { allSucceeded = false }
            completed += 1
            if completed == total {
                DispatchQueue.main.async { self.completion(self.allSucceeded) }
            }
        }
    }
}