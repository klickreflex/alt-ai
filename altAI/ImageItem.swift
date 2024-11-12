import SwiftUI

struct ImageItem: Identifiable {
    let id = UUID()
    let image: NSImage
    var altText: String
}
