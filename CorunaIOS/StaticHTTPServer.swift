import Foundation
import Network

final class StaticHTTPServer {
    typealias Logger = (String, LogLevel) -> Void

    private let rootURL: URL
    private let logger: Logger
    private let readyHandler: () -> Void
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "coruna.http.server")

    private(set) var port: UInt16 = 34306

    var indexURL: URL {
        URL(string: "http://127.0.0.1:\(port)/index.html")!
    }

    init(rootURL: URL, logger: @escaping Logger, readyHandler: @escaping () -> Void) throws {
        self.rootURL = rootURL.standardizedFileURL
        self.logger = logger
        self.readyHandler = readyHandler
    }

    func start() throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        guard let serverPort = NWEndpoint.Port(rawValue: port) else {
            throw ServerError.portUnavailable
        }

        let listener = try NWListener(using: parameters, on: serverPort)
        listener.service = nil
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.logger("listener ready", .success)
                self?.readyHandler()
            case .failed(let error):
                self?.logger("listener failed: \(error)", .error)
            case .cancelled:
                self?.logger("listener cancelled", .info)
            default:
                break
            }
        }

        self.listener = listener
        listener.start(queue: queue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(on: connection, data: Data())
    }

    private func receiveRequest(on connection: NWConnection, data: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16 * 1024) { [weak self] chunk, _, isComplete, error in
            guard let self else { return }

            if let error {
                self.logger("receive failed: \(error)", .error)
                connection.cancel()
                return
            }

            var requestData = data
            if let chunk {
                requestData.append(chunk)
            }

            if requestData.range(of: Data("\r\n\r\n".utf8)) != nil || isComplete {
                self.respond(to: requestData, on: connection)
            } else {
                self.receiveRequest(on: connection, data: requestData)
            }
        }
    }

    private func respond(to requestData: Data, on connection: NWConnection) {
        guard let request = String(data: requestData, encoding: .utf8),
              let firstLine = request.components(separatedBy: "\r\n").first else {
            send(status: 400, reason: "Bad Request", body: Data("Bad Request".utf8), contentType: "text/plain", on: connection)
            return
        }

        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2 else {
            send(status: 400, reason: "Bad Request", body: Data("Bad Request".utf8), contentType: "text/plain", on: connection)
            return
        }

        let method = String(parts[0])
        let target = String(parts[1])

        guard method == "GET" || method == "HEAD" else {
            send(status: 405, reason: "Method Not Allowed", body: Data("Method Not Allowed".utf8), contentType: "text/plain", on: connection)
            return
        }

        let path = normalizedPath(from: target)
        let fileURL = rootURL.appendingPathComponent(path).standardizedFileURL

        guard fileURL.path.hasPrefix(rootURL.path) else {
            send(status: 403, reason: "Forbidden", body: Data("Forbidden".utf8), contentType: "text/plain", on: connection)
            logger("\(method) \(target) -> 403", .error)
            return
        }

        do {
            let values = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
            let resolvedURL = values.isDirectory == true ? fileURL.appendingPathComponent("index.html") : fileURL
            let body = method == "HEAD" ? Data() : try Data(contentsOf: resolvedURL)
            let contentLength = try FileManager.default.attributesOfItem(atPath: resolvedURL.path)[.size] as? NSNumber
            send(
                status: 200,
                reason: "OK",
                body: body,
                contentType: Self.contentType(for: resolvedURL.pathExtension),
                contentLength: contentLength?.intValue ?? body.count,
                on: connection
            )
            logger("\(method) /\(path) -> 200", .request)
        } catch {
            send(status: 404, reason: "Not Found", body: Data("Not Found".utf8), contentType: "text/plain", on: connection)
            logger("\(method) /\(path) -> 404", .error)
        }
    }

    private func normalizedPath(from target: String) -> String {
        let path = target.split(separator: "?", maxSplits: 1).first.map(String.init) ?? "/"
        let trimmed = path.removingPercentEncoding ?? path
        let relative = trimmed == "/" ? "index.html" : String(trimmed.drop(while: { $0 == "/" }))
        return relative.isEmpty ? "index.html" : relative
    }

    private func send(
        status: Int,
        reason: String,
        body: Data,
        contentType: String,
        contentLength: Int? = nil,
        on connection: NWConnection
    ) {
        let headers = [
            "HTTP/1.1 \(status) \(reason)",
            "Content-Type: \(contentType)",
            "Content-Length: \(contentLength ?? body.count)",
            "Cache-Control: no-store",
            "Access-Control-Allow-Origin: *",
            "Connection: close",
            "",
            ""
        ].joined(separator: "\r\n")

        var response = Data(headers.utf8)
        response.append(body)
        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private static func contentType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "html":
            return "text/html; charset=utf-8"
        case "js":
            return "application/javascript; charset=utf-8"
        case "json":
            return "application/json; charset=utf-8"
        case "css":
            return "text/css; charset=utf-8"
        case "dylib", "bin":
            return "application/octet-stream"
        default:
            return "application/octet-stream"
        }
    }
}

enum ServerError: LocalizedError {
    case portUnavailable

    var errorDescription: String? {
        switch self {
        case .portUnavailable:
            return "Unable to allocate a local HTTP port."
        }
    }
}
