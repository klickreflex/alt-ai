import Foundation
import SwiftUI

// Response models
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

class OpenAIService {
    static let shared = OpenAIService()
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession

    private var maxImageDimension: CGFloat {
        CGFloat(SettingsManager.shared.imageMaxDimension)
    }

    private var jpegCompressionQuality: CGFloat {
        CGFloat(SettingsManager.shared.imageQuality)
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    private var apiKey: String {
        SettingsManager.shared.apiKey
    }

    private func getPromptForLanguage(_ language: String) -> String {
        switch language {
        case "German":
            return "Generiere einen prägnanten Alt-Text für dieses Bild."
        case "French":
            return "Générez un texte alternatif concis pour cette image."
        case "Spanish":
            return "Genera un texto alternativo conciso para esta imagen."
        default: // English
            return "Generate a concise alt text description for this image."
        }
    }

    private func resizeImage(_ image: NSImage) -> NSImage {
        let currentSize = image.size

        // If image is smaller than max dimension, return original
        if currentSize.width <= maxImageDimension && currentSize.height <= maxImageDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = currentSize.width / currentSize.height
        let newSize: NSSize

        if ratio > 1 {
            // Wider than tall
            newSize = NSSize(width: maxImageDimension, height: maxImageDimension / ratio)
        } else {
            // Taller than wide
            newSize = NSSize(width: maxImageDimension * ratio, height: maxImageDimension)
        }

        // Create resized image
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: currentSize),
                  operation: .copy,
                  fraction: 1.0)
        resizedImage.unlockFocus()

        return resizedImage
    }

    private func processImage(_ image: NSImage) -> Data? {
        // Resize image
        let resizedImage = resizeImage(image)

        // Convert to compressed JPEG
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg,
                                                 properties: [.compressionFactor: jpegCompressionQuality]) else {
            return nil
        }

        // Print size info for debugging
        print("JPEG size: \(jpegData.count / 1024)KB")
        return jpegData
    }

    func generateAltText(forImageData imageData: Data) async throws -> String {
        print("Starting API request...")
        print("API Key length: \(apiKey.count)")
        print("Base URL: \(baseURL)")

        guard !apiKey.isEmpty else {
            throw NSError(domain: "OpenAI", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "API key not set. Please add your OpenAI API key in settings."])
        }

        guard let originalImage = NSImage(data: imageData) else {
            throw NSError(domain: "OpenAI", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }

        guard let processedImageData = processImage(originalImage) else {
            throw NSError(domain: "OpenAI", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        print("Original size: \(imageData.count / 1024)KB")
        print("Processed size: \(processedImageData.count / 1024)KB")

        let base64Image = processedImageData.base64EncodedString()

        let prompt = getPromptForLanguage(SettingsManager.shared.selectedLanguage)

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw NSError(domain: "OpenAI", code: 4,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create request payload"])
        }

        do {
            print("Sending request...")
            let (data, urlResponse) = try await session.data(for: request)
            print("Got response: \(urlResponse)")

            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }

            let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return apiResponse.choices.first?.message.content ?? "No description generated"

        } catch let error as NSError {
            print("Detailed error: \(error)")
            throw error
        }
    }
}
