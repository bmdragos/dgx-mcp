import Foundation

// MARK: - MCP Protocol (Generic, Reusable)

enum MCP {
    struct Tool {
        let name: String
        let description: String
        let inputSchema: [String: Any]

        var asDict: [String: Any] {
            ["name": name, "description": description, "inputSchema": inputSchema]
        }
    }

    static func run(
        name: String,
        version: String,
        tools: [Tool],
        handler: @escaping (String, [String: Any]) async throws -> String
    ) async {
        setbuf(stdout, nil)
        setbuf(stderr, nil)
        log("\(name) MCP server starting...")

        while let line = readLine() {
            guard !line.isEmpty else { continue }

            do {
                let response = try await handleRequest(line, name: name, version: version, tools: tools, handler: handler)
                if !response.isEmpty {
                    print(response)
                }
            } catch {
                print(errorResponse(id: nil, code: -32700, message: "Parse error: \(error)"))
            }
        }
    }

    private static func handleRequest(
        _ json: String,
        name: String,
        version: String,
        tools: [Tool],
        handler: @escaping (String, [String: Any]) async throws -> String
    ) async throws -> String {
        guard let data = json.data(using: .utf8) else {
            throw MCPError.invalidJSON
        }

        let request = try JSONDecoder().decode(Request.self, from: data)

        switch request.method {
        case "initialize":
            let result: [String: Any] = [
                "protocolVersion": "2024-11-05",
                "capabilities": ["tools": [:] as [String: Any]],
                "serverInfo": ["name": name, "version": version]
            ]
            return successResponse(id: request.id, result: result)

        case "tools/list":
            return successResponse(id: request.id, result: ["tools": tools.map { $0.asDict }])

        case "tools/call":
            guard let params = request.params,
                  let toolName = params["name"] as? String else {
                return errorResponse(id: request.id, code: -32602, message: "Invalid params")
            }
            let arguments = params["arguments"] as? [String: Any] ?? [:]

            do {
                let result = try await handler(toolName, arguments)
                return successResponse(id: request.id, result: ["content": [["type": "text", "text": result]]])
            } catch {
                return errorResponse(id: request.id, code: -32000, message: "\(error)")
            }

        case "notifications/initialized":
            return ""

        default:
            return errorResponse(id: request.id, code: -32601, message: "Method not found: \(request.method)")
        }
    }

    static func successResponse(id: RequestID?, result: [String: Any]) -> String {
        var response: [String: Any] = ["jsonrpc": "2.0", "result": result]
        if let id = id { response["id"] = id.value }
        return toJSON(response)
    }

    static func errorResponse(id: RequestID?, code: Int, message: String) -> String {
        var response: [String: Any] = ["jsonrpc": "2.0", "error": ["code": code, "message": message]]
        if let id = id { response["id"] = id.value }
        return toJSON(response)
    }

    static func toJSON(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"error\": \"Failed to serialize response\"}"
        }
        return string
    }

    static func log(_ message: String) {
        FileHandle.standardError.write("\(message)\n".data(using: .utf8)!)
    }
}

// MARK: - JSON-RPC Types

enum MCPError: Error {
    case invalidJSON
    case unknownTool(String)
}

struct Request: Decodable {
    let jsonrpc: String
    let method: String
    let id: RequestID?
    let params: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case jsonrpc, method, id, params
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        method = try container.decode(String.self, forKey: .method)
        id = try container.decodeIfPresent(RequestID.self, forKey: .id)
        if let paramsData = try? container.decode(AnyCodable.self, forKey: .params) {
            params = paramsData.value as? [String: Any]
        } else {
            params = nil
        }
    }
}

struct RequestID: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid ID type")
            )
        }
    }
}

struct AnyCodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }
}
