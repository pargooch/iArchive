import UIKit
import Photos

struct PhotoSaver {
    static func save(images: [UIImage], completion: @escaping (Bool) -> Void) {
        guard !images.isEmpty else { completion(false); return }
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                completion(false)
                return
            }
            PHPhotoLibrary.shared().performChanges({
                for image in images {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
            }) { success, _ in
                completion(success)
            }
        }
    }
}