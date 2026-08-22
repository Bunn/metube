import SwiftUI

struct StatusBanner: View {
    let message: String

    var body: some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 11))
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
    }

    private var content: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .padding(.horizontal)
    }
}
