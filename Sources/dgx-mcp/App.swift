@main
struct App {
    static func main() async {
        await MCP.run(name: "dgx", version: "2.2.0", tools: DGX.tools, handler: DGX.call)
    }
}
