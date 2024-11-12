import SwiftUI
import UniformTypeIdentifiers

struct ImageGridView: View {
    @State private var imageItems: [ImageItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingFilePicker = false
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }

            if !isLoading {
                Color.clear
                    .frame(height: 2)
            }

            if settings.apiKey.isEmpty {
                VStack {
                    Text("OpenAI API key not set")
                        .font(.headline)
                    SettingsLink {
                        Text("Open Settings")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 20) {
                        ForEach(imageItems) { item in
                            ImageItemView(item: binding(for: item),
                                        onGenerateAltText: { generateAltText(for: item) })
                        }
                    }
                    .padding()
                }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

            HStack {
                Button("Open image(s)") {
                    showingFilePicker = true
                }

                Button("Generate all missing alt texts") {
                    generateMissingAltTexts()
                }
                .disabled(isLoading)
            }
            .padding()
        }
        .animation(.easeInOut, value: isLoading)
        .onDrop(of: [.image], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.png, .jpeg, .gif,
                                UTType("org.webmproject.webp")!],  // WebP support
            allowsMultipleSelection: true
        ) { result in
            Task {
                do {
                    let urls = try result.get()
                    print("Selected URLs: \(urls)")  // Debug print

                    for url in urls {
                        guard url.startAccessingSecurityScopedResource() else {
                            print("Failed to access file: \(url)")  // Debug print
                            continue
                        }

                        defer { url.stopAccessingSecurityScopedResource() }

                        if let image = NSImage(contentsOf: url) {
                            await MainActor.run {
                                imageItems.append(ImageItem(image: image, altText: ""))
                                print("Added image from: \(url)")  // Debug print
                            }
                        } else {
                            print("Failed to create image from: \(url)")  // Debug print
                        }
                    }
                } catch {
                    print("Error selecting files: \(error)")  // Debug print
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func binding(for item: ImageItem) -> Binding<ImageItem> {
        Binding(
            get: { item },
            set: { newValue in
                if let index = imageItems.firstIndex(where: { $0.id == item.id }) {
                    imageItems[index] = newValue
                }
            }
        )
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                guard let url = item as? URL else { return }
                guard let image = NSImage(contentsOf: url) else { return }

                DispatchQueue.main.async {
                    imageItems.append(ImageItem(image: image, altText: ""))
                }
            }
        }
    }

    private func generateAltText(for item: ImageItem) {
        guard let index = imageItems.firstIndex(where: { $0.id == item.id }) else { return }

        isLoading = true
        Task {
            do {
                let imageData: Data? = await MainActor.run {
                    return item.image.tiffRepresentation
                }

                guard let imageData = imageData else {
                    print("Failed to get image data")
                    await MainActor.run { isLoading = false }
                    return
                }

                let altText = try await OpenAIService.shared.generateAltText(forImageData: imageData)
                await MainActor.run {
                    imageItems[index].altText = altText
                    isLoading = false
                }
            } catch {
                print("Error generating alt text: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func generateMissingAltTexts() {
        isLoading = true
        Task {
            for (index, item) in imageItems.enumerated() where item.altText.isEmpty {
                do {
                    let imageData: Data? = await MainActor.run {
                        return item.image.tiffRepresentation
                    }

                    guard let imageData = imageData else {
                        print("Failed to get image data")
                        continue
                    }

                    let altText = try await OpenAIService.shared.generateAltText(forImageData: imageData)
                    await MainActor.run {
                        imageItems[index].altText = altText
                    }
                } catch {
                    print("Error generating alt text: \(error)")
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
