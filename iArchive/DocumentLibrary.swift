import SwiftUI
import Combine

struct PersistedDocument: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var date: Date
    var pagePaths: [String] // relative paths inside app documents directory
}

final class DocumentLibrary: ObservableObject {
    @Published private(set) var documents: [PersistedDocument] = []

    private let metadataKey = "iArchive.documents.metadata"

    init() {
        load()
    }

    // MARK: - Public API

    func addDocument(images: [UIImage], suggestedName: String? = nil) {
        guard !images.isEmpty else { return }
        let id = UUID()
        let name = suggestedName ?? defaultName()
        let date = Date()
        let baseFolder = id.uuidString

        var savedPaths: [String] = []
        for (idx, img) in images.enumerated() {
            let filename = "page_\(idx + 1).jpg"
            let relativePath = baseFolder + "/" + filename
            if saveImage(img, toRelativePath: relativePath) {
                savedPaths.append(relativePath)
            }
        }

        guard !savedPaths.isEmpty else { return }
        let doc = PersistedDocument(id: id, name: name, date: date, pagePaths: savedPaths)
        documents.append(doc)
        saveMetadata()
    }

    func deleteDocument(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard documents.indices.contains(index) else { continue }
            let doc = documents[index]
            // remove files
            removeFiles(for: doc)
            documents.remove(at: index)
        }
        saveMetadata()
    }

    func clearAll() {
        for doc in documents { removeFiles(for: doc) }
        documents.removeAll()
        saveMetadata()
    }

    func renameDocument(id: UUID, to newName: String) {
        guard let idx = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[idx].name = newName
        saveMetadata()
    }

    func thumbnail(for doc: PersistedDocument) -> UIImage? {
        guard let first = doc.pagePaths.first else { return nil }
        return loadImage(fromRelativePath: first)
    }

    func images(for doc: PersistedDocument) -> [UIImage] {
        doc.pagePaths.compactMap { loadImage(fromRelativePath: $0) }
    }

    // MARK: - Persistence

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func saveImage(_ image: UIImage, toRelativePath relativePath: String) -> Bool {
        let url = documentsDirectory().appendingPathComponent(relativePath)
        let folderURL = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            if let data = image.jpegData(compressionQuality: 0.9) {
                try data.write(to: url)
                return true
            }
        } catch {
            print("Failed saving image: \(error)")
        }
        return false
    }

    private func loadImage(fromRelativePath relativePath: String) -> UIImage? {
        let url = documentsDirectory().appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return nil }
        return image
    }

    private func removeFiles(for doc: PersistedDocument) {
        let baseFolder = doc.pagePaths.first?.split(separator: "/").first.map(String.init) ?? doc.id.uuidString
        let folderURL = documentsDirectory().appendingPathComponent(baseFolder)
        try? FileManager.default.removeItem(at: folderURL)
    }

    private func defaultName() -> String {
        return "Document \(documents.count + 1)"
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: metadataKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([PersistedDocument].self, from: data)
            documents = decoded
        } catch {
            print("Failed to decode metadata: \(error)")
        }
    }

    private func saveMetadata() {
        do {
            let data = try JSONEncoder().encode(documents)
            UserDefaults.standard.set(data, forKey: metadataKey)
        } catch {
            print("Failed to encode metadata: \(error)")
        }
    }
}