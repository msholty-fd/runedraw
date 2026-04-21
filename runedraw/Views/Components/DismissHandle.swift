import SwiftUI

/// A drag handle shown at the top of sheets to signal swipe-to-dismiss.
struct DismissHandle: View {
    var tint: Color = .gray

    var body: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(tint.opacity(0.55))
                .frame(width: 38, height: 4)
                .padding(.top, 10)

            Text("swipe down to close")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(tint.opacity(0.35))
                .tracking(1)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
    }
}
