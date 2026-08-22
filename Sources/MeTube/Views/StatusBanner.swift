import SwiftUI

struct StatusBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
            .shadow(radius: 8, y: 3)
            .padding(.horizontal)
    }
}
