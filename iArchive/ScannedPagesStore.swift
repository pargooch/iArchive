import SwiftUI
import Combine

final class ScannedPagesStore: ObservableObject {
    @Published var pages: [UIImage] = []

    func remove(at offsets: IndexSet) {
        pages.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        pages.move(fromOffsets: source, toOffset: destination)
    }

    func clear() {
        pages.removeAll()
    }
}