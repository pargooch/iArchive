import SwiftUI

struct DocumentDetailView: View {
    @EnvironmentObject private var store: ScannedPagesStore
    @Environment(\.dismiss) private var dismiss

    let index: Int
    let image: UIImage

    @State private var showRename = false
    @State private var tempName: String = ""

    private var currentName: String {
        if store.names.indices.contains(index) {
            return store.names[index]
        } else {
            return "Document \(index + 1)"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .navigationTitle(currentName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Rename") {
                        tempName = currentName
                        showRename = true
                    }
                }
            }
        }
        .sheet(isPresented: $showRename) {
            NavigationView {
                Form {
                    Section(header: Text("Document Name")) {
                        TextField("Enter name", text: $tempName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(false)
                    }
                }
                .navigationTitle("Rename")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { showRename = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { saveName() }
                            .disabled(tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func saveName() {
        let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if store.names.indices.contains(index) {
            store.names[index] = trimmed
        } else {
            while store.names.count <= index {
                store.names.append("Document \(store.names.count + 1)")
            }
            store.names[index] = trimmed
        }
        showRename = false
    }
}