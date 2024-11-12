import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("openai_api_key") var apiKey: String = ""
    @AppStorage("selected_language") var selectedLanguage: String = "English"
    @AppStorage("image_max_dimension") var imageMaxDimension: Double = 1200
    @AppStorage("image_quality") var imageQuality: Double = 0.7

    static let availableLanguages = [
        "English",
        "German",
        "French",
        "Spanish"
    ]

    static let dimensionRange = 512.0...2048.0
    static let qualityRange = 0.3...1.0

    private init() {}
}
