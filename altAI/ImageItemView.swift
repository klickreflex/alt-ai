import SwiftUI

struct ImageItemView: View {
    @Binding var item: ImageItem
    let onGenerateAltText: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                Image(nsImage: item.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .layoutPriority(1)

                TextEditor(text: $item.altText)
                    .font(.system(.body))
                    .frame(height: 55)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
            }

            HStack {
                Spacer()
                Button("Generate alt text") {
                    onGenerateAltText()
                }
                .disabled(!item.altText.isEmpty)

                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.altText, forType: .string)
                }
                .disabled(item.altText.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
