import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var isKeyVisible = false

    var body: some View {
        Form {
            Section("OpenAI API") {
                HStack {
                    if isKeyVisible {
                        TextField("API Key", text: $settings.apiKey)
                    } else {
                        SecureField("API Key", text: $settings.apiKey)
                    }

                    Button(action: {
                        isKeyVisible.toggle()
                    }) {
                        Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                Text("Get your API key from [OpenAI](https://platform.openai.com/api-keys)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            Section("Language") {
                Picker("Alt Text Language", selection: $settings.selectedLanguage) {
                    ForEach(SettingsManager.availableLanguages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
            }

            Section("Image Processing") {
                VStack(alignment: .leading) {
                    Text("Maximum Image Dimension: \(Int(settings.imageMaxDimension))px")
                    Slider(
                        value: $settings.imageMaxDimension,
                        in: SettingsManager.dimensionRange,
                        step: 128
                    )
                    Text("Smaller values reduce API costs but may affect quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading) {
                    Text("Image Quality: \(Int(settings.imageQuality * 100))%")
                    Slider(
                        value: $settings.imageQuality,
                        in: SettingsManager.qualityRange,
                        step: 0.1
                    )
                    Text("Lower quality reduces API costs but may affect visual details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}
