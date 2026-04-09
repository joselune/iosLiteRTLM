import SwiftUI

struct Loading: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Checking model...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
