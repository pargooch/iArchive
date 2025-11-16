# iArchive

iArchive is a lightweight, privacy-friendly document scanner and archive app built with SwiftUI. It lets you scan pages using the device camera, import existing images or files, organize them into documents, and export or share them as PDFs or images.

<details>
  <summary><strong>Libraries & Kits Used</strong></summary>

- `SwiftUI` — declarative UI and navigation.
- `UIKit` — bridging via `UIViewControllerRepresentable` (ShareSheet, pickers).
- `VisionKit` — `VNDocumentCameraViewController` for full‑screen document scanning.
- `AVFoundation` — camera session and preview layer management.
- `Vision` — rectangle detection and overlay assistance.
- `PDFKit` — PDF composition and export utilities.
- `PhotosUI` — `PHPickerViewController` for gallery import.
- `Photos` — save images to Photos library.
- `UniformTypeIdentifiers` — typed file selection (`UTType.image`, `UTType.pdf`).
- `Combine` — reactive state (`ObservableObject`, `@Published`).
- `CoreImage` — image handling utilities.
- `Foundation` — local file storage and persistence.

</details>

<details>
  <summary><strong>Feature Overview</strong></summary>

- Fast camera scanning with automatic document detection.
- Post-scan actions: export to PDF, share images, save to Photos.
- Unified camera options modal with solid background.
- Home list with thumbnails, search, and document detail pages.
- Multi-select with bottom-left trash button; camera on bottom-right.
- Settings with Help and About sheets.
- Privacy-friendly: all processing on-device; no uploads.

</details>

<details>
  <summary><strong>Screens & User Flows</strong></summary>

- Home
  - Browse documents, search by name, open details.
  - Enter selection mode; multi-select and delete via trash.
  - Tap camera to open options: Add from Gallery, Scan, Choose from Files.
- Scan
  - Full-screen scan with edge detection; capture pages.
  - After scanning, Post Scan actions modal: export/share/save.
- Settings
  - Help and About; camera/trash overlay hidden on this tab.

</details>

<details>
  <summary><strong>Setup & Requirements</strong></summary>

- Xcode 15+ recommended.
- iOS device required for VisionKit scanning (Simulator unsupported).
- iOS 15+ for best SwiftUI coverage.

Setup
- Clone the repo:
  ```bash
  git clone https://github.com/<your-org>/iArchive.git
  cd iArchive
  ```
- Open `iArchive.xcodeproj` in Xcode.
- Set Signing (Target → Signing & Capabilities → Team).
- Run on a device.

</details>

<details>
  <summary><strong>Permissions & Info.plist Keys</strong></summary>

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

Purpose
- Camera access for scanning
- Photos access for import/save
- Files access via Document Picker

</details>

<details>
  <summary><strong>Usage Guide</strong></summary>

- Scanning
  - Home → Camera → Scan with Camera → capture pages → finish.
  - Use Post Scan actions to export/share/save.
- Importing
  - Add from Gallery (PhotosUI) or Choose from Files (UIDocumentPicker).
- Managing Documents
  - Tap to open details, rename, and view pages.
  - Selection mode → select items → trash to delete.

</details>

<details>
  <summary><strong>Project Structure</strong></summary>

- `iArchiveApp.swift` — App entry.
- `ContentView.swift` — TabView (Home/Settings), bottom action row gated to Home.
- `HomeView` — documents list, search, selection mode, detail sheets.
- `SettingsView` — Help and About.
- `CameraOptionsView.swift` — options sheet (Gallery/Scan/Files).
- `DocumentScannerView.swift` — VisionKit scanner.
- `CameraManager.swift` — AVFoundation camera + Vision overlay support.
- `CameraPreview.swift` — preview layer.
- `RectangleOverlay.swift` — overlay rendering.
- `PostScanActionsView.swift` — export/share/save.
- `DocumentLibrary.swift` — persistence and thumbnails.
- `DocumentDetailView.swift` — detail view per document.
- `PhotoPicker.swift` / `DocumentPicker.swift` — importers.
- `Theme.swift` — brand color and styling helpers.

</details>

<details>
  <summary><strong>Architecture Notes</strong></summary>

- State Lifting
  - Selection state lifted to `ContentView` for global trash/camera row.
  - Overlay shown only on Home via `TabView` selection tag.
- Modal Presentation
  - Camera options presented as a sheet (large detent, unified background).
  - Scanner presented full-screen for best UX.
- Post-Scan Flow
  - Add images to library; optional Post Scan actions module.

</details>

<details>
  <summary><strong>Theming & Accessibility</strong></summary>

- Brand color `brandPrimary` in `Theme.swift`.
- High-contrast buttons and adequate touch targets.
- Accessibility labels on key controls (e.g. camera button).

</details>

<details>
  <summary><strong>Troubleshooting</strong></summary>

- Scanner doesn’t open on Simulator → use a real device.
- Camera permission denied → enable in Settings → Privacy → Camera.
- Photos import/save issues → ensure Photos permissions; verify plist keys.
- Signing errors → set a valid Team under Signing & Capabilities.

</details>

<details>
  <summary><strong>Contributing</strong></summary>

- Fork, branch, and open a PR with focused changes.
- Align with existing code style and include screenshots for UI changes.

</details>

<details>
  <summary><strong>License & Acknowledgements</strong></summary>

- License: see `LICENSE`.
- Thanks to VisionKit, AVFoundation, PDFKit, PhotosUI, and SwiftUI.

</details>