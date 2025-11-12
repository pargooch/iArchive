import SwiftUI

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let name: String?

    var body: some View {
        NavigationView {
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .navigationTitle(name ?? "Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }
            }
        }
    }
}