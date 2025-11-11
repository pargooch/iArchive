import SwiftUI
import Combine

final class ScannedPagesStore: ObservableObject {
    @Published var pages: [UIImage] = [] {
        didSet {
            if names.count < pages.count {
                let start = names.count
                for i in start..<pages.count {
                    names.append("Document \(i + 1)")
                }
            } else if names.count > pages.count {
                names = Array(names.prefix(pages.count))
            }
        }
    }
    @Published var names: [String] = []

    func remove(at offsets: IndexSet) {
        pages.remove(atOffsets: offsets)
        names.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        pages.move(fromOffsets: source, toOffset: destination)
        names.move(fromOffsets: source, toOffset: destination)
    }

    func clear() {
        pages.removeAll()
        names.removeAll()
    }

    func add(images: [UIImage]) {
        guard !images.isEmpty else { return }
        let start = pages.count
        pages.append(contentsOf: images)
        for i in 0..<images.count {
            names.append("Document \(start + i + 1)")
        }
    }
}