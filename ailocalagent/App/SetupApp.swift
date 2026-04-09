import SwiftUI

struct SetupApp: View {

    @State private var viewModel = SetupViewModel()
    @State private var chatViewModel: ChatViewModel?

    var body: some View {
        Group {
            switch viewModel.modelSetupState {
            case .checking:
                Loading()
            case .notInstalled, .downloading:
                downloadModelView
            case .ready:
                if let chatViewModel {
                    ChatApp(viewModel: chatViewModel)
                }
            case .error(let message):
                errorView(message: message)
            }
        }
        .task {
            await viewModel.setup()
        }
        .onChange(of: viewModel.modelSetupState) { _, newState in
            if case .ready = newState, chatViewModel == nil {
                let inference = LiteRTInferenceService()
                let url = try! viewModel.modelLocalURL()
                chatViewModel = ChatViewModel(inference: inference, modelURL: url)
            }
        }
        .onChange(of: chatViewModel?.requestDeleteAndRedownload) { _, shouldReset in
            if shouldReset == true {
                chatViewModel = nil
                viewModel.modelSetupState = .notInstalled
            }
        }
    }

    private var downloadModelView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.indigo)

            VStack(spacing: 8) {
                Text("AI Model Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Download the AI model to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.downloadProgress ?? 0)
                        .tint(.indigo)
                        .padding(.horizontal, 40)
                    if let progress = viewModel.downloadProgress {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }

            Spacer()

            Button {
                Task { try? await viewModel.downloadModel() }
            } label: {
                Label("Download Model", systemImage: "arrow.down.to.line")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.horizontal, 40)
            .disabled(viewModel.isDownloading)

            Spacer()
                .frame(height: 40)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                Task { await viewModel.setup() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .fontWeight(.medium)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 32)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)

            Spacer()
        }
    }
}

#Preview {
    SetupApp()
}
