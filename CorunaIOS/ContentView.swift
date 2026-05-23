import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var controller: ServerController
    @State private var isShowingWebView = false

    var body: some View {
        NavigationView {
            VStack(spacing: 14) {
                header
                controls
                logView
            }
            .padding(16)
            .navigationTitle("Coruna")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingWebView) {
                if let url = controller.serverURL {
                    WebViewSheet(url: url)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(controller.isReady ? Color.green : (controller.isRunning ? Color.orange : Color.secondary))
                .frame(width: 10, height: 10)
            Text(controller.statusText)
                .font(.subheadline.monospaced())
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                controller.toggleServer()
            } label: {
                Label {
                    Text(LocalizedStringKey(controller.isRunning ? "button.stop" : "button.start"))
                } icon: {
                    Image(systemName: controller.isRunning ? "stop.fill" : "play.fill")
                }
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                openInWebView()
            } label: {
                Label("WK", systemImage: "rectangle.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                openInSafari()
            } label: {
                Label("Safari", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
    }

    private var logView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(controller.logEntries) { entry in
                        Text(entry.message)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(entry.level.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .id(entry.id)
                    }
                }
                .padding(12)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onChange(of: controller.logEntries.count) { _ in
                if let last = controller.logEntries.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func openInWebView() {
        controller.startServer {
            isShowingWebView = true
        }
    }

    private func openInSafari() {
        controller.startServer {
            guard let url = controller.serverURL else { return }
            UIApplication.shared.open(url)
        }
    }
}

private extension LogLevel {
    var color: Color {
        switch self {
        case .info:
            return .primary
        case .request:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(controller: ServerController())
    }
}
