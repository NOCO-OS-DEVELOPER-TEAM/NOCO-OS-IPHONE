import SwiftUI
import PhotosUI

struct PhotosAppView: View {
    @State private var items: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $items, maxSelectionCount: 12, matching: .images) {
                Label("Fotos auswählen", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .nocoGlass(cornerRadius: 16)
            }
            .onChange(of: items) { _, newItems in
                Task { await loadImages(from: newItems) }
            }

            if images.isEmpty {
                ContentUnavailableView("Keine Fotos", systemImage: "photo", description: Text("Wähle Bilder aus deiner Mediathek."))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(images.indices, id: \.self) { i in
                            Image(uiImage: images[i])
                                .resizable()
                                .scaledToFill()
                                .frame(height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        var loaded: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(image)
            }
        }
        images = loaded
    }
}
