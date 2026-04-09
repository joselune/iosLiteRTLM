import SwiftUI

struct ChatApp: View {
    @State var viewModel: ChatViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundFill
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    messageList
                    inputBar
                }
            }
            .navigationTitle("Local AI")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Picker("Backend", selection: $viewModel.selectedBackend) {
                            ForEach(AppBackend.allCases, id: \.self) { b in
                                Text(b.rawValue.uppercased()).tag(b)
                            }
                        }
                    } label: {
                        Label(viewModel.selectedBackend.rawValue.uppercased(), systemImage: "cpu")
                            .font(.caption)
                    }
                    .disabled(viewModel.screenState == .generating || viewModel.screenState == .loadingModel)
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await viewModel.newChat() }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(viewModel.screenState != .idle)
                }
            }
            .onChange(of: viewModel.selectedBackend) {
                Task { await viewModel.loadModel() }
            }
        }
        .overlay(alignment: .top) { toastOverlay }
        .overlay { modelLoadingOverlay }
        .alert("Failed to load model", isPresented: $viewModel.showErrorAlert) {
            if viewModel.selectedBackend != .cpu {
                Button("Fallback to CPU") {
                    Task { await viewModel.fallbackToCPU() }
                }
            }
            Button("Retry") {
                Task { await viewModel.loadModel() }
            }
            Button("Delete & Re-download", role: .destructive) {
                viewModel.deleteModelFile()
            }
            Button("Dismiss", role: .cancel) { }
        } message: {
            if viewModel.isRunningOnSimulator {
                Text("\(viewModel.errorMessage)\n\nThe AI engine may not work on the iOS Simulator. Try a real device or macOS.")
            } else {
                Text(viewModel.errorMessage)
            }
        }
        .task {
            await viewModel.loadModel()
        }
    }

    // MARK: - Cross-platform Colors

    private var backgroundFill: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    private var inputFieldBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.screenState == .generating,
                       viewModel.messages.last?.role != .assistant {
                        ThinkingIndicator()
                            .id("thinking")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.messages.last?.text) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.screenState) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastID = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(inputFieldBackground, in: RoundedRectangle(cornerRadius: 22))
                .disabled(viewModel.screenState == .generating)

            if viewModel.screenState == .generating {
                Button(action: viewModel.stopGenerating) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.red, in: Circle())
                }
            } else {
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(sendButtonDisabled ? Color.gray : Color.indigo, in: Circle())
                }
                .disabled(sendButtonDisabled)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var sendButtonDisabled: Bool {
        viewModel.screenState != .idle || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Model Loading Overlay

    @ViewBuilder
    private var modelLoadingOverlay: some View {
        if viewModel.screenState == .loadingModel {
            ZStack {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading model...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastOverlay: some View {
        if viewModel.showModelLoadedToast {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Model ready")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut) {
                        viewModel.showModelLoadedToast = false
                    }
                }
            }
            .animation(.spring(duration: 0.4), value: viewModel.showModelLoadedToast)
        }
    }
}
