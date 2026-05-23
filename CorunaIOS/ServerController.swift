import Foundation

@MainActor
final class ServerController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var isReady = false
    @Published private(set) var serverURL: URL?
    @Published private(set) var logEntries: [LogEntry] = []

    private var server: StaticHTTPServer?
    private var pendingOpen: (() -> Void)?

    var statusText: String {
        if let serverURL {
            return isRunning ? serverURL.absoluteString : "已停止"
        }
        return "未启动"
    }

    func toggleServer() {
        isRunning ? stopServer() : startServer()
    }

    @discardableResult
    func ensureServerRunning() -> Bool {
        if isReady {
            return true
        }
        startServer()
        return false
    }

    func startServer(whenReady action: @escaping () -> Void) {
        if isReady {
            action()
            return
        }
        pendingOpen = action
        startServer()
    }

    func startServer() {
        guard !isRunning else { return }
        guard let rootURL = Bundle.main.resourceURL?.appendingPathComponent("CorunaWeb", isDirectory: true) else {
            append("未找到 bundle resourceURL", level: .error)
            return
        }

        do {
            let server = try StaticHTTPServer(rootURL: rootURL, logger: { [weak self] message, level in
                Task { @MainActor in
                    self?.append(message, level: level)
                }
            }, readyHandler: { [weak self] in
                Task { @MainActor in
                    self?.markReady()
                }
            }
            )
            try server.start()
            self.server = server
            self.serverURL = server.indexURL
            self.isRunning = true
            self.isReady = false
            append("HTTP server starting: \(server.indexURL.absoluteString)", level: .info)
        } catch {
            append("HTTP server start failed: \(error.localizedDescription)", level: .error)
        }
    }

    func stopServer() {
        guard isRunning else { return }
        server?.stop()
        server = nil
        isRunning = false
        isReady = false
        pendingOpen = nil
        append("HTTP server stopped", level: .info)
    }

    private func markReady() {
        guard isRunning else { return }
        isReady = true
        append("HTTP server ready: \(serverURL?.absoluteString ?? "-")", level: .success)
        let action = pendingOpen
        pendingOpen = nil
        action?()
    }

    private func append(_ message: String, level: LogLevel) {
        let timestamp = Self.timestampFormatter.string(from: Date())
        logEntries.append(LogEntry(message: "[\(timestamp)] \(message)", level: level))
        if logEntries.count > 500 {
            logEntries.removeFirst(logEntries.count - 500)
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let level: LogLevel
}

enum LogLevel {
    case info
    case request
    case success
    case error
}
