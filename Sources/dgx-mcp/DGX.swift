import Foundation

// MARK: - DGX Spark MCP Implementation

enum DGX {
    private static let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".dgx/config.json")
    private static let statePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".dgx/state.json")

    // MARK: - Tool Definitions

    static let tools: [MCP.Tool] = [
        MCP.Tool(
            name: "dgx_status",
            description: "Show DGX Spark status: host connectivity, GPU info, container states, and project sync times",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        MCP.Tool(
            name: "dgx_containers",
            description: "List all Docker containers on DGX Spark (including unconfigured ones)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        MCP.Tool(
            name: "dgx_check_updates",
            description: "Check for NGC container image updates. Shows current version vs latest available.",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        MCP.Tool(
            name: "dgx_sync",
            description: "Sync project files between local machine and DGX Spark",
            inputSchema: [
                "type": "object",
                "properties": [
                    "direction": ["type": "string", "enum": ["push", "pull"], "description": "push = local to DGX, pull = DGX results to local"],
                    "project": ["type": "string", "description": "Project name (optional, auto-detected from cwd)"]
                ] as [String: Any],
                "required": ["direction"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_run",
            description: "Full workflow: sync code to DGX, run command in container, sync results back. Use for running experiments.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "command": ["type": "string", "description": "Command to run in container (e.g., 'python run_gpu.py --K 1e9')"],
                    "project": ["type": "string", "description": "Project name"]
                ] as [String: Any],
                "required": ["command"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_exec",
            description: "Run a command in the DGX container without syncing. For quick commands.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "command": ["type": "string", "description": "Command to run"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": ["command"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_upgrade",
            description: "Upgrade container to latest NGC image version",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name"],
                    "confirm": ["type": "boolean", "description": "Skip confirmation prompt"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_logs",
            description: "View container logs",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (default: twinprime)"],
                    "lines": ["type": "integer", "description": "Number of lines to show (default: 50)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_start",
            description: "Start a stopped container",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_stop",
            description: "Stop a running container",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_gpu",
            description: "Show GPU status (memory, utilization, temperature)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        MCP.Tool(
            name: "dgx_disk",
            description: "Show disk space on DGX",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        // MARK: - Embedding Server Tools
        MCP.Tool(
            name: "dgx_embed_status",
            description: "Check embedding server status: running/stopped, model info, GPU memory, active jobs",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        MCP.Tool(
            name: "dgx_embed_start",
            description: "Start the embedding server (llama-embed-nemotron-8b). Takes ~90s for model load + warmup.",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        MCP.Tool(
            name: "dgx_embed_stop",
            description: "Stop the embedding server gracefully",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        // MARK: - Generic Service Tools
        MCP.Tool(
            name: "dgx_service_status",
            description: "Check service status. Lists all services if no service specified, or details for a specific service.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "service": ["type": "string", "description": "Service name (e.g., 'embedding', 'onnx-inference'). Lists all if omitted."]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_service_start",
            description: "Start a service defined in config.json",
            inputSchema: [
                "type": "object",
                "properties": [
                    "service": ["type": "string", "description": "Service name (e.g., 'embedding', 'onnx-inference')"]
                ] as [String: Any],
                "required": ["service"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_service_stop",
            description: "Stop a running service",
            inputSchema: [
                "type": "object",
                "properties": [
                    "service": ["type": "string", "description": "Service name (e.g., 'embedding', 'onnx-inference')"]
                ] as [String: Any],
                "required": ["service"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_telemetry",
            description: "Get real-time telemetry from DGXDash app. Returns GPU util, memory, temp, container stats, trends, and alerts. Use this to monitor resource usage during long-running computations.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (optional, reads container-specific telemetry if available)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_job_start",
            description: "Start a background job on DGX. Returns immediately with job_id. Use dgx_jobs to check status and dgx_job_log to view output. Perfect for long-running GPU computations.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "command": ["type": "string", "description": "Command to run (e.g., 'python run_gpu.py --K 1e9')"],
                    "name": ["type": "string", "description": "Human-readable job name for display (e.g., 'Twin prime K=1e9')"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"],
                    "workdir": ["type": "string", "description": "Working directory (default: /workspace)"]
                ] as [String: Any],
                "required": ["command"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_jobs",
            description: "List background jobs on DGX. Shows running and recent completed jobs with their status.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (default: twinprime)"],
                    "limit": ["type": "integer", "description": "Number of recent jobs to show (default: 5)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_job_log",
            description: "View output from a background job. Use 'tail' mode to see recent lines, 'full' for complete output.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "job_id": ["type": "string", "description": "Job ID from dgx_job_start"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"],
                    "lines": ["type": "integer", "description": "Number of lines to show (default: 50, use 0 for full output)"]
                ] as [String: Any],
                "required": ["job_id"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_job_kill",
            description: "Kill a running background job.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "job_id": ["type": "string", "description": "Job ID to kill"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": ["job_id"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_job_retry",
            description: "Re-run a completed or failed job with the same command.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "job_id": ["type": "string", "description": "Job ID to retry"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": ["job_id"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_job_clean",
            description: "Remove old job files to clean up disk space.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "older_than_hours": ["type": "integer", "description": "Remove jobs older than N hours (default: 24)"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"],
                    "keep_last": ["type": "integer", "description": "Always keep the N most recent jobs (default: 5)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_job_watch",
            description: "Watch a running job with live updates. Shows new output since last check, GPU stats inline, and elapsed time.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "job_id": ["type": "string", "description": "Job ID to watch"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": ["job_id"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_job_compare",
            description: "Compare metrics between two jobs. Shows differences in selection bias, runtime, phase timings, etc.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "job1": ["type": "string", "description": "First job ID"],
                    "job2": ["type": "string", "description": "Second job ID"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": ["job1", "job2"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_job_stats",
            description: "Show job history statistics: total jobs, success rate, average runtime, fastest/slowest runs.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (default: twinprime)"],
                    "limit": ["type": "integer", "description": "Number of recent jobs to analyze (default: 20)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_template_save",
            description: "Save a command as a named template for quick re-use.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string", "description": "Template name (e.g., 'twin-prime-1e9')"],
                    "command": ["type": "string", "description": "Command to save"],
                    "description": ["type": "string", "description": "Optional description"],
                    "project": ["type": "string", "description": "Associated project for auto-sync"]
                ] as [String: Any],
                "required": ["name", "command"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_template_run",
            description: "Run a saved template. Optionally syncs project first and results after.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string", "description": "Template name to run"],
                    "sync": ["type": "boolean", "description": "Sync project before and results after (default: false)"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": ["name"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_template_list",
            description: "List all saved command templates.",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]]
        ),
        MCP.Tool(
            name: "dgx_template_delete",
            description: "Delete a saved template.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string", "description": "Template name to delete"]
                ] as [String: Any],
                "required": ["name"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_queue_add",
            description: "Add a job to the execution queue. Jobs run sequentially.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "command": ["type": "string", "description": "Command to queue"],
                    "template": ["type": "string", "description": "Or use a template name instead of command"],
                    "container": ["type": "string", "description": "Container name (default: twinprime)"],
                    "workdir": ["type": "string", "description": "Working directory (default: /workspace)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_queue_list",
            description: "Show the current job queue and running job.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_queue_clear",
            description: "Clear all pending jobs from the queue (does not affect running job).",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_queue_start",
            description: "Start processing the job queue. Runs jobs sequentially until queue is empty.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name (default: twinprime)"]
                ] as [String: Any],
                "required": [] as [String]
            ]
        ),
        // MARK: - Config Management Tools
        MCP.Tool(
            name: "dgx_config_add_service",
            description: "Add a new service to config.json for dgx_service_* commands",
            inputSchema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string", "description": "Service name (e.g., 'onnx-inference')"],
                    "container": ["type": "string", "description": "Container name to run the service in"],
                    "process": ["type": "string", "description": "Process pattern for pgrep detection (e.g., 'uvicorn', 'python.*server')"],
                    "start_cmd": ["type": "string", "description": "Command to start the service (e.g., 'cd /workspace && python server.py --port 8081')"],
                    "port": ["type": "integer", "description": "Port the service listens on"],
                    "health": ["type": "string", "description": "Health endpoint path (e.g., '/health'). Optional."],
                    "description": ["type": "string", "description": "Human-readable description. Optional."]
                ] as [String: Any],
                "required": ["name", "container", "process", "start_cmd", "port"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_config_add_project",
            description: "Add a new project to config.json for dgx_sync commands",
            inputSchema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string", "description": "Project name (e.g., 'my-project')"],
                    "local": ["type": "string", "description": "Local path to project (e.g., '/Users/bd/Coding/my-project')"],
                    "container": ["type": "string", "description": "Container name for the project"],
                    "remote": ["type": "string", "description": "Remote path in container (e.g., '/workspace/my-project')"],
                    "exclude": ["type": "array", "items": ["type": "string"], "description": "Patterns to exclude from sync (e.g., ['.git', '__pycache__', '.venv'])"]
                ] as [String: Any],
                "required": ["name", "local", "container", "remote"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_config_add_container",
            description: "Add a new container to config.json",
            inputSchema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string", "description": "Container name (e.g., 'my-container')"],
                    "host": ["type": "string", "description": "Host name from hosts config (default: 'spark')"],
                    "image": ["type": "string", "description": "Docker image (e.g., 'nvcr.io/nvidia/pytorch:25.01-py3')"],
                    "workdir": ["type": "string", "description": "Default working directory (e.g., '/workspace')"]
                ] as [String: Any],
                "required": ["name", "image", "workdir"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_container_create",
            description: "Create a Docker container on DGX with correct volume mounts for associated projects. Creates host directories, then runs docker with per-project mounts mapping ~/{project} to {remote} in container.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "container": ["type": "string", "description": "Container name from config"],
                    "ports": ["type": "array", "items": ["type": "string"], "description": "Port mappings (e.g., ['8081:8081'])"]
                ] as [String: Any],
                "required": ["container"] as [String]
            ]
        ),
        MCP.Tool(
            name: "dgx_install",
            description: "Install apt packages in a container. Runs apt-get update && apt-get install.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "packages": ["type": "array", "items": ["type": "string"], "description": "Package names to install (e.g., ['ffmpeg', 'vim'])"],
                    "container": ["type": "string", "description": "Container name (default: from config)"]
                ] as [String: Any],
                "required": ["packages"] as [String]
            ]
        )
    ]

    // MARK: - Dispatch

    static func call(_ name: String, _ args: [String: Any]) async throws -> String {
        switch name {
        case "dgx_status":      return try await status()
        case "dgx_gpu":         return try await gpu()
        case "dgx_disk":        return try await disk()
        case "dgx_containers":  return try await containers()
        case "dgx_logs":        return try await logs(container: args["container"] as? String, lines: args["lines"] as? Int)
        case "dgx_start":       return try await start(container: args["container"] as? String)
        case "dgx_stop":        return try await stop(container: args["container"] as? String)
        // Embedding server (aliases for backward compatibility)
        case "dgx_embed_status": return try await serviceStatus(service: "embedding")
        case "dgx_embed_start":  return try await serviceStart(service: "embedding")
        case "dgx_embed_stop":   return try await serviceStop(service: "embedding")
        // Generic service management
        case "dgx_service_status": return try await serviceStatus(service: args["service"] as? String)
        case "dgx_service_start":
            guard let svc = args["service"] as? String else { throw MCPError.unknownTool("dgx_service_start requires service") }
            return try await serviceStart(service: svc)
        case "dgx_service_stop":
            guard let svc = args["service"] as? String else { throw MCPError.unknownTool("dgx_service_stop requires service") }
            return try await serviceStop(service: svc)
        case "dgx_exec":
            guard let cmd = args["command"] as? String else { throw MCPError.unknownTool("dgx_exec requires command") }
            return try await exec(command: cmd, container: args["container"] as? String)
        case "dgx_sync":
            guard let dir = args["direction"] as? String else { throw MCPError.unknownTool("dgx_sync requires direction") }
            return try await sync(direction: dir, project: args["project"] as? String)
        case "dgx_run":
            guard let cmd = args["command"] as? String else { throw MCPError.unknownTool("dgx_run requires command") }
            return try await run(command: cmd, project: args["project"] as? String)
        case "dgx_check_updates": return try await checkUpdates()
        case "dgx_upgrade":       return try await upgrade(container: args["container"] as? String, confirm: args["confirm"] as? Bool ?? false)
        case "dgx_telemetry":     return try await telemetry(container: args["container"] as? String)
        case "dgx_job_start":
            guard let cmd = args["command"] as? String else { throw MCPError.unknownTool("dgx_job_start requires command") }
            return try await jobStart(command: cmd, name: args["name"] as? String, container: args["container"] as? String, workdir: args["workdir"] as? String)
        case "dgx_jobs":          return try await jobsList(container: args["container"] as? String, limit: args["limit"] as? Int)
        case "dgx_job_log":
            guard let jobId = args["job_id"] as? String else { throw MCPError.unknownTool("dgx_job_log requires job_id") }
            return try await jobLog(jobId: jobId, container: args["container"] as? String, lines: args["lines"] as? Int)
        case "dgx_job_kill":
            guard let jobId = args["job_id"] as? String else { throw MCPError.unknownTool("dgx_job_kill requires job_id") }
            return try await jobKill(jobId: jobId, container: args["container"] as? String)
        case "dgx_job_retry":
            guard let jobId = args["job_id"] as? String else { throw MCPError.unknownTool("dgx_job_retry requires job_id") }
            return try await jobRetry(jobId: jobId, container: args["container"] as? String)
        case "dgx_job_clean":
            return try await jobClean(olderThanHours: args["older_than_hours"] as? Int, container: args["container"] as? String, keepLast: args["keep_last"] as? Int)
        case "dgx_job_watch":
            guard let jobId = args["job_id"] as? String else { throw MCPError.unknownTool("dgx_job_watch requires job_id") }
            return try await jobWatch(jobId: jobId, container: args["container"] as? String)
        case "dgx_job_compare":
            guard let job1 = args["job1"] as? String, let job2 = args["job2"] as? String else {
                throw MCPError.unknownTool("dgx_job_compare requires job1 and job2")
            }
            return try await jobCompare(job1: job1, job2: job2, container: args["container"] as? String)
        case "dgx_job_stats":
            return try await jobStats(container: args["container"] as? String, limit: args["limit"] as? Int)
        case "dgx_template_save":
            guard let name = args["name"] as? String, let cmd = args["command"] as? String else {
                throw MCPError.unknownTool("dgx_template_save requires name and command")
            }
            return try await templateSave(name: name, command: cmd, description: args["description"] as? String, project: args["project"] as? String)
        case "dgx_template_run":
            guard let name = args["name"] as? String else { throw MCPError.unknownTool("dgx_template_run requires name") }
            return try await templateRun(name: name, sync: args["sync"] as? Bool ?? false, container: args["container"] as? String)
        case "dgx_template_list":
            return try await templateList()
        case "dgx_template_delete":
            guard let name = args["name"] as? String else { throw MCPError.unknownTool("dgx_template_delete requires name") }
            return try await templateDelete(name: name)
        case "dgx_queue_add":
            return try await queueAdd(command: args["command"] as? String, template: args["template"] as? String, container: args["container"] as? String, workdir: args["workdir"] as? String)
        case "dgx_queue_list":
            return try await queueList(container: args["container"] as? String)
        case "dgx_queue_clear":
            return try await queueClear(container: args["container"] as? String)
        case "dgx_queue_start":
            return try await queueStart(container: args["container"] as? String)
        // Config management
        case "dgx_config_add_service":
            guard let name = args["name"] as? String,
                  let container = args["container"] as? String,
                  let process = args["process"] as? String,
                  let startCmd = args["start_cmd"] as? String,
                  let port = args["port"] as? Int else {
                throw MCPError.unknownTool("dgx_config_add_service requires name, container, process, start_cmd, port")
            }
            return try configAddService(name: name, container: container, process: process, startCmd: startCmd, port: port,
                                         health: args["health"] as? String, description: args["description"] as? String)
        case "dgx_config_add_project":
            guard let name = args["name"] as? String,
                  let local = args["local"] as? String,
                  let container = args["container"] as? String,
                  let remote = args["remote"] as? String else {
                throw MCPError.unknownTool("dgx_config_add_project requires name, local, container, remote")
            }
            let exclude = args["exclude"] as? [String] ?? [".git", "__pycache__", ".DS_Store"]
            return try configAddProject(name: name, local: local, container: container, remote: remote, exclude: exclude)
        case "dgx_config_add_container":
            guard let name = args["name"] as? String,
                  let image = args["image"] as? String,
                  let workdir = args["workdir"] as? String else {
                throw MCPError.unknownTool("dgx_config_add_container requires name, image, workdir")
            }
            let host = args["host"] as? String ?? "spark"
            return try configAddContainer(name: name, host: host, image: image, workdir: workdir)
        case "dgx_container_create":
            guard let container = args["container"] as? String else {
                throw MCPError.unknownTool("dgx_container_create requires container")
            }
            let ports = args["ports"] as? [String] ?? []
            return try await containerCreate(container: container, ports: ports)
        case "dgx_install":
            guard let packages = args["packages"] as? [String], !packages.isEmpty else {
                throw MCPError.unknownTool("dgx_install requires packages array")
            }
            return try await install(packages: packages, container: args["container"] as? String)
        default:
            throw MCPError.unknownTool(name)
        }
    }

    // MARK: - Config

    struct Config: Codable {
        var hosts: [String: Host]
        var containers: [String: Container]
        var projects: [String: Project]
        var services: [String: Service]?

        struct Service: Codable {
            var container: String
            var process: String
            var startCmd: String
            var port: Int
            var health: String?
            var description: String?
            enum CodingKeys: String, CodingKey {
                case container, process, startCmd = "start_cmd", port, health, description
            }
        }

        struct Host: Codable {
            let hostname: String?
            let fallbackIP: String?
            let user: String
            enum CodingKeys: String, CodingKey { case hostname, fallbackIP = "fallback_ip", user }
            var ssh: String { hostname ?? fallbackIP ?? "localhost" }
        }

        struct Container: Codable {
            var host: String
            var image: String
            var workdir: String
        }

        struct Project: Codable {
            var local: String
            var container: String
            var remote: String
            var exclude: [String]
            var results: String?  // Optional: subdirectory to pull (e.g., "output"). If nil, pulls whole project.
        }
    }

    struct State: Codable {
        var projects: [String: ProjectState]
        var templates: [String: Template]
        var jobWatchState: [String: JobWatchState]  // job_id -> last read position
        var lastProject: String?  // Most recently used project for convenience

        init() {
            projects = [:]
            templates = [:]
            jobWatchState = [:]
            lastProject = nil
        }

        struct ProjectState: Codable {
            var lastPush: String?
            var lastPull: String?
            enum CodingKeys: String, CodingKey { case lastPush = "last_push", lastPull = "last_pull" }
        }

        struct Template: Codable {
            let command: String
            let description: String?
            let project: String?
            let createdAt: String
        }

        struct JobWatchState: Codable {
            var lastBytePosition: Int
            var lastCheckTime: String
        }
    }

    private static func loadConfig() throws -> Config {
        let data = try Data(contentsOf: configPath)
        return try JSONDecoder().decode(Config.self, from: data)
    }

    private static func saveConfig(_ config: Config) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(config).write(to: configPath)
    }

    // MARK: - Config Management

    private static func configAddService(name: String, container: String, process: String, startCmd: String, port: Int, health: String?, description: String?) throws -> String {
        var config = try loadConfig()

        // Check if service already exists
        if config.services?[name] != nil {
            return "❌ Service '\(name)' already exists. Remove it first or use a different name."
        }

        let service = Config.Service(container: container, process: process, startCmd: startCmd, port: port, health: health, description: description)

        if config.services == nil {
            config.services = [:]
        }
        config.services?[name] = service

        try saveConfig(config)

        var lines = ["✓ Added service '\(name)'"]
        lines.append("")
        lines.append("**Container:** \(container)")
        lines.append("**Process:** \(process)")
        lines.append("**Port:** \(port)")
        if let h = health { lines.append("**Health:** \(h)") }
        if let d = description { lines.append("**Description:** \(d)") }
        lines.append("")
        lines.append("Use `dgx_service_start service:\(name)` to start")

        return lines.joined(separator: "\n")
    }

    private static func configAddProject(name: String, local: String, container: String, remote: String, exclude: [String]) throws -> String {
        var config = try loadConfig()

        // Check if project already exists
        if config.projects[name] != nil {
            return "❌ Project '\(name)' already exists. Remove it first or use a different name."
        }

        // Verify container exists
        if config.containers[container] == nil {
            return "❌ Container '\(container)' not found in config. Add it first with dgx_config_add_container."
        }

        let project = Config.Project(local: local, container: container, remote: remote, exclude: exclude)
        config.projects[name] = project

        try saveConfig(config)

        var lines = ["✓ Added project '\(name)'"]
        lines.append("")
        lines.append("**Local:** \(local)")
        lines.append("**Container:** \(container)")
        lines.append("**Remote:** \(remote)")
        lines.append("**Exclude:** \(exclude.joined(separator: ", "))")
        lines.append("")
        lines.append("Use `dgx_sync direction:push project:\(name)` to sync")

        return lines.joined(separator: "\n")
    }

    private static func configAddContainer(name: String, host: String, image: String, workdir: String) throws -> String {
        var config = try loadConfig()

        // Check if container already exists
        if config.containers[name] != nil {
            return "❌ Container '\(name)' already exists. Remove it first or use a different name."
        }

        // Verify host exists
        if config.hosts[host] == nil {
            return "❌ Host '\(host)' not found in config."
        }

        let container = Config.Container(host: host, image: image, workdir: workdir)
        config.containers[name] = container

        try saveConfig(config)

        var lines = ["✓ Added container '\(name)'"]
        lines.append("")
        lines.append("**Host:** \(host)")
        lines.append("**Image:** \(image)")
        lines.append("**Workdir:** \(workdir)")
        lines.append("")
        lines.append("Next: Use `dgx_container_create container:\(name)` to create the container on DGX")

        return lines.joined(separator: "\n")
    }

    private static func containerCreate(container containerName: String, ports: [String]) async throws -> String {
        let config = try loadConfig()

        // Verify container is in config
        guard let containerConfig = config.containers[containerName] else {
            let available = config.containers.keys.joined(separator: ", ")
            return "❌ Container '\(containerName)' not found in config. Available: \(available)"
        }

        // Check if container already exists on host
        let (existing, _) = try await ssh("docker inspect \(containerName) --format '{{.State.Status}}' 2>/dev/null || echo 'not_found'")
        if existing.trimmingCharacters(in: .whitespacesAndNewlines) != "not_found" {
            return "❌ Container '\(containerName)' already exists on DGX (status: \(existing.trimmingCharacters(in: .whitespacesAndNewlines))). Remove it first with: docker rm -f \(containerName)"
        }

        // Get host user for home directory
        guard let hostConfig = config.hosts[containerConfig.host] else {
            return "❌ Host '\(containerConfig.host)' not found in config."
        }
        let user = hostConfig.user

        // Find all projects associated with this container
        var mounts: [(host: String, container: String)] = []
        var projectNames: [String] = []
        for (projectName, project) in config.projects where project.container == containerName {
            // Host path: ~/{project_name} (rsync convention)
            let hostPath = "/home/\(user)/\(projectName)"
            // Container path: from project config (e.g., /workspace/demucs)
            let containerPath = project.remote
            mounts.append((hostPath, containerPath))
            projectNames.append(projectName)
        }

        var lines: [String] = []
        lines.append("Creating container '\(containerName)'...")
        lines.append("")

        // Create host directories
        if !mounts.isEmpty {
            lines.append("**1. Creating host directories:**")
            for mount in mounts {
                let (_, code) = try await ssh("mkdir -p \(mount.host)")
                if code == 0 {
                    lines.append("   ✓ \(mount.host)")
                } else {
                    lines.append("   ❌ Failed to create \(mount.host)")
                }
            }
            lines.append("")
        }

        // Build docker run command
        var dockerCmd = "docker run -d --name \(containerName) --runtime=nvidia --gpus all"

        // Add volume mounts
        for mount in mounts {
            dockerCmd += " -v \(mount.host):\(mount.container)"
        }

        // Add port mappings
        for port in ports {
            dockerCmd += " -p \(port)"
        }

        // Add standard GPU container flags
        dockerCmd += " --ipc=host --ulimit memlock=-1 --ulimit stack=67108864"

        // Set workdir and image
        dockerCmd += " -w \(containerConfig.workdir) \(containerConfig.image) tail -f /dev/null"

        lines.append("**2. Running docker:**")
        lines.append("```")
        lines.append(dockerCmd)
        lines.append("```")
        lines.append("")

        let (result, code) = try await ssh(dockerCmd)
        if code == 0 {
            lines.append("✓ Container created successfully")
            lines.append("")
            lines.append("**Volume mounts:**")
            for (i, mount) in mounts.enumerated() {
                lines.append("  \(projectNames[i]): \(mount.host) → \(mount.container)")
            }
            lines.append("")
            lines.append("rsync syncs to ~/{project_name} on host, which maps to {remote} in container.")
        } else {
            lines.append("❌ Failed to create container:")
            lines.append(result)
        }

        return lines.joined(separator: "\n")
    }

    private static func install(packages: [String], container containerName: String?) async throws -> String {
        let config = try loadConfig()

        // Resolve container name
        let resolvedContainer: String
        if let containerName = containerName {
            resolvedContainer = containerName
        } else if let firstContainer = config.containers.keys.first {
            resolvedContainer = firstContainer
        } else {
            return "❌ No container specified and none found in config."
        }

        // Verify container exists in config
        guard config.containers[resolvedContainer] != nil else {
            let available = config.containers.keys.joined(separator: ", ")
            return "❌ Container '\(resolvedContainer)' not found. Available: \(available)"
        }

        let packageList = packages.joined(separator: " ")
        var lines: [String] = []
        lines.append("Installing packages in '\(resolvedContainer)': \(packageList)")
        lines.append("")

        // Run apt-get update
        lines.append("Updating package lists...")
        let (_, updateCode) = try await ssh("docker exec \(resolvedContainer) apt-get update -qq")
        if updateCode != 0 {
            lines.append("⚠️ apt-get update had warnings (continuing anyway)")
        }

        // Install packages
        lines.append("Installing: \(packageList)")
        let (result, code) = try await ssh("docker exec \(resolvedContainer) apt-get install -y -qq \(packageList)")

        if code == 0 {
            lines.append("✓ Packages installed successfully")
        } else {
            lines.append("❌ Installation failed:")
            lines.append(result)
        }

        return lines.joined(separator: "\n")
    }

    private static func loadState() -> State {
        guard let data = try? Data(contentsOf: statePath),
              let state = try? JSONDecoder().decode(State.self, from: data) else {
            return State()
        }
        return state
    }

    private static func saveState(_ state: State) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        try encoder.encode(state).write(to: statePath)
    }

    private static func getHost() throws -> String {
        let config = try loadConfig()
        guard let host = config.hosts["spark"] else {
            throw MCPError.unknownTool("No 'spark' host configured")
        }
        return host.ssh
    }

    // MARK: - Shell Helpers

    private static func shell(_ command: String) async throws -> (out: String, code: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()

        var output = String(data: outData, encoding: .utf8) ?? ""
        if let err = String(data: errData, encoding: .utf8), !err.isEmpty {
            if !output.isEmpty { output += "\n" }
            output += err
        }

        return (output.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus)
    }

    // MARK: - SSH Connection Pooling

    /// Control socket path for SSH multiplexing
    private static var sshControlPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.ssh/dgx-mcp-control-%r@%h:%p"
    }

    /// SSH options for connection multiplexing (ControlMaster)
    private static let sshControlOpts = [
        "-o", "ControlMaster=auto",
        "-o", "ControlPersist=300",  // Keep socket open 5 minutes after last use
        "-o", "ConnectTimeout=5",
        "-o", "BatchMode=yes"
    ]

    private static func ssh(_ command: String) async throws -> (out: String, code: Int32) {
        let host = try getHost()
        let escaped = command.replacingOccurrences(of: "'", with: "'\"'\"'")
        let controlPath = "-o ControlPath=\(sshControlPath)"
        let opts = sshControlOpts.joined(separator: " ")
        return try await shell("ssh \(opts) \(controlPath) \(host) '\(escaped)'")
    }

    // MARK: - Job Cache for DGXDash

    /// Local cache file for DGXDash to read job state without SSH
    private static let jobCachePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".dgx/jobs-cache.json")

    /// Job cache structure - written locally for DGXDash to consume
    struct JobCache: Codable {
        var version: Int = 1
        var updatedAt: Date
        var host: String
        var container: String
        var running: RunningJob?
        var recent: [CompletedJob]

        struct RunningJob: Codable {
            var id: String
            var name: String?   // Human-readable display name
            var command: String
            var startedAt: Int  // Unix timestamp
            var workdir: String?
        }

        struct CompletedJob: Codable {
            var id: String
            var name: String?   // Human-readable display name
            var command: String
            var status: String  // completed, failed, killed
            var exitCode: Int
            var startedAt: Int
            var duration: Int   // seconds
            var hasErrors: Bool
        }
    }

    /// Write job cache atomically for DGXDash consumption
    private static func writeJobCache(_ cache: JobCache) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(cache)
            let cacheDir = jobCachePath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

            // Atomic write: write to temp file then rename
            let tempPath = jobCachePath.appendingPathExtension("tmp")
            try data.write(to: tempPath)
            try FileManager.default.removeItem(at: jobCachePath)
        } catch {
            // Ignore - cache is best-effort
        }

        // Final rename
        let tempPath = jobCachePath.appendingPathExtension("tmp")
        try? FileManager.default.moveItem(at: tempPath, to: jobCachePath)
    }

    /// Read current job cache (for internal use)
    private static func readJobCache() -> JobCache? {
        guard let data = try? Data(contentsOf: jobCachePath) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(JobCache.self, from: data)
    }

    /// Update cache from parsed job list data
    /// This is the authoritative sync point - corrects any stale state
    private static func updateJobCacheFromList(
        jobs: [(id: String, exitCode: String, status: String, cmd: String, start: String, end: String, duration: Int, now: String, hasErrors: Bool)],
        container: String
    ) {
        let host = (try? getHost()) ?? "spark-dcf7.local"

        // Read existing cache to preserve names
        let existingCache = readJobCache()
        let existingNames: [String: String] = {
            var names: [String: String] = [:]
            if let running = existingCache?.running, let name = running.name {
                names[running.id] = name
            }
            for job in existingCache?.recent ?? [] {
                if let name = job.name {
                    names[job.id] = name
                }
            }
            return names
        }()

        var running: JobCache.RunningJob? = nil
        var recent: [JobCache.CompletedJob] = []

        for job in jobs {
            let startTime = Int(job.start) ?? 0
            let existingName = existingNames[job.id]  // Preserve name if we had it

            if job.status == "running" && job.exitCode == "-" {
                // Running job
                running = JobCache.RunningJob(
                    id: job.id,
                    name: existingName,
                    command: job.cmd,
                    startedAt: startTime,
                    workdir: nil
                )
            } else {
                // Completed/failed/killed job
                let exitCode = Int(job.exitCode) ?? -1
                let status: String
                if job.status == "killed" {
                    status = "killed"
                } else if exitCode == 0 {
                    status = "completed"
                } else {
                    status = "failed"
                }

                // Use pre-calculated duration from remote
                recent.append(JobCache.CompletedJob(
                    id: job.id,
                    name: existingName,
                    command: job.cmd,
                    status: status,
                    exitCode: exitCode,
                    startedAt: startTime,
                    duration: job.duration,
                    hasErrors: job.hasErrors
                ))
            }
        }

        let cache = JobCache(
            updatedAt: Date(),
            host: host,
            container: container,
            running: running,
            recent: recent
        )

        writeJobCache(cache)
    }

    /// Optimistically add a new running job to cache (called from jobStart)
    private static func addRunningJobToCache(jobId: String, name: String?, command: String, container: String, workdir: String?) {
        var cache = readJobCache() ?? JobCache(
            updatedAt: Date(),
            host: (try? getHost()) ?? "spark-dcf7.local",
            container: container,
            running: nil,
            recent: []
        )

        // Move any existing running job to recent (shouldn't happen normally)
        if let prev = cache.running {
            let completed = JobCache.CompletedJob(
                id: prev.id,
                name: prev.name,
                command: prev.command,
                status: "unknown",
                exitCode: -1,
                startedAt: prev.startedAt,
                duration: Int(Date().timeIntervalSince1970) - prev.startedAt,
                hasErrors: false
            )
            cache.recent.insert(completed, at: 0)
            if cache.recent.count > 10 { cache.recent.removeLast() }
        }

        cache.running = JobCache.RunningJob(
            id: jobId,
            name: name,
            command: command,
            startedAt: Int(Date().timeIntervalSince1970),
            workdir: workdir
        )
        cache.updatedAt = Date()
        cache.container = container

        writeJobCache(cache)
    }

    /// Mark running job as killed (called from jobKill)
    private static func markJobKilledInCache(jobId: String) {
        guard var cache = readJobCache() else { return }

        if let running = cache.running, running.id == jobId {
            let killed = JobCache.CompletedJob(
                id: running.id,
                name: running.name,
                command: running.command,
                status: "killed",
                exitCode: -9,
                startedAt: running.startedAt,
                duration: Int(Date().timeIntervalSince1970) - running.startedAt,
                hasErrors: false
            )
            cache.recent.insert(killed, at: 0)
            if cache.recent.count > 10 { cache.recent.removeLast() }
            cache.running = nil
            cache.updatedAt = Date()
            writeJobCache(cache)
        }
    }

    // MARK: - Commands

    private static func status() async throws -> String {
        let config = try loadConfig()
        let state = loadState()
        let host = config.hosts["spark"]!.ssh

        var out = "=== DGX Spark Status ===\n\n"

        // Host check
        let (_, reachable) = try await shell("ssh -o ConnectTimeout=5 \(host) echo ok")
        if reachable != 0 {
            return out + "Host: \(host) - UNREACHABLE"
        }
        out += "Host: \(host) - OK\n"

        // GPU
        let (gpuInfo, gpuOk) = try await ssh("nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader")
        if gpuOk == 0 { out += "GPU: \(gpuInfo)\n" }

        // Containers
        out += "\n=== Containers ===\n\n"
        for (name, container) in config.containers {
            let (inspect, ok) = try await ssh("docker inspect \(name) --format '{{.State.Status}} {{.Config.Image}}'")
            if ok == 0 {
                let parts = inspect.split(separator: " ", maxSplits: 1)
                if parts.count >= 2 {
                    let status = String(parts[0])
                    let image = String(parts[1])
                    out += "  \(status == "running" ? "●" : "○") \(name): \(status)\n    Image: \(image)\n"
                    let (created, _) = try await ssh("docker inspect \(image) --format '{{.Created}}'")
                    out += "    Created: \(String(created.prefix(10)))\n"
                }
            } else {
                out += "  ✗ \(name): not found\n    Config image: \(container.image)\n"
            }
        }

        // Projects
        out += "\n=== Projects ===\n\n"
        for (name, project) in config.projects {
            let lastPush = state.projects[name]?.lastPush ?? "never"
            out += "  \(name):\n    Local: \(project.local)\n    Remote: \(project.remote)\n    Last push: \(lastPush)\n"
        }

        return out
    }

    private static func gpu() async throws -> String {
        var out = "=== GPU Status ===\n\n"
        let (result, ok) = try await ssh("nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader")
        if ok == 0 {
            let parts = result.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 5 {
                out += "  GPU: \(parts[0])\n  Memory: \(parts[1]) / \(parts[2])\n  Utilization: \(parts[3])\n  Temperature: \(parts[4])\n"
            } else {
                out += "  \(result)\n"
            }
        } else {
            out += "Failed to query GPU"
        }
        return out
    }

    private static func disk() async throws -> String {
        var out = "=== Disk Space ===\n\n"
        let (result, ok) = try await ssh("df -h /home ~")
        out += ok == 0 ? result : "Failed to query disk space"
        return out
    }

    private static func telemetry(container: String?) async throws -> String {
        let telemetryDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".dgx/telemetry")

        // Try container-specific first if specified
        var telemetryFile = telemetryDir.appendingPathComponent("current.json")
        if let container = container {
            let containerFile = telemetryDir
                .appendingPathComponent("containers/\(container)/current.json")
            if FileManager.default.fileExists(atPath: containerFile.path) {
                telemetryFile = containerFile
            }
        }

        // Check if DGXDash is running and writing telemetry
        guard FileManager.default.fileExists(atPath: telemetryFile.path) else {
            return "No telemetry available. Is DGXDash running?\nFalling back to direct query...\n\n" + (try await gpu())
        }

        // Check file age - if older than 10s, DGXDash may not be running
        let attrs = try? FileManager.default.attributesOfItem(atPath: telemetryFile.path)
        if let modDate = attrs?[.modificationDate] as? Date {
            let age = Date().timeIntervalSince(modDate)
            if age > 10 {
                return "Telemetry stale (\(Int(age))s old). Is DGXDash running?\nFalling back to direct query...\n\n" + (try await gpu())
            }
        }

        // Read and format telemetry
        let data = try Data(contentsOf: telemetryFile)

        // Parse the stats structure from DGXDash
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Failed to parse telemetry"
        }

        var out = ""

        // Summary first (most important for Claude Code)
        if let summary = json["summary"] as? String {
            out += "\(summary)\n\n"
        }

        // Alerts
        if let alerts = json["alerts"] as? [[String: Any]], !alerts.isEmpty {
            out += "Alerts:\n"
            for alert in alerts {
                let level = alert["level"] as? String ?? "info"
                let msg = alert["message"] as? String ?? ""
                let icon = level == "critical" ? "⛔" : "⚠️"
                out += "  \(icon) \(msg)\n"
            }
            out += "\n"
        }

        // Current values
        if let current = json["current"] as? [String: Any] {
            if let gpu = current["gpu"] as? [String: Any] {
                let util = gpu["utilization"] as? Int ?? 0
                let temp = gpu["temperature"] as? Int ?? 0
                let power = gpu["powerWatts"] as? Double ?? 0
                out += "GPU: \(util)% util, \(temp)°C, \(String(format: "%.0f", power))W\n"
            }

            if let containers = current["containers"] as? [[String: Any]] {
                for c in containers {
                    let name = c["name"] as? String ?? "?"
                    let mem = c["memoryUsedGB"] as? Double ?? 0
                    let limit = c["memoryLimitGB"] as? Double ?? 0
                    let cpu = c["cpuPercent"] as? Double ?? 0
                    let pct = limit > 0 ? Int((mem / limit) * 100) : 0
                    out += "Container \(name): \(String(format: "%.1f", mem))GB/\(String(format: "%.0f", limit))GB (\(pct)%), CPU \(String(format: "%.1f", cpu))%\n"
                }
            }
        }

        // Trends
        if let trend = json["trend"] as? [String: Any] {
            let memTrend = trend["memoryTrend"] as? String ?? "stable"
            if let rate = trend["memoryRateGBPerMin"] as? Double, abs(rate) > 0.1 {
                let direction = rate > 0 ? "+" : ""
                out += "\nMemory trend: \(memTrend) (\(direction)\(String(format: "%.1f", rate)) GB/min)\n"
            }
        }

        return out
    }

    private static func containers() async throws -> String {
        let config = try loadConfig()
        let configured = Set(config.containers.keys)
        var out = "=== All Containers on DGX ===\n\n"

        let (result, ok) = try await ssh("docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}'")
        if ok != 0 { return "Failed to list containers" }

        for line in result.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 2)
            if parts.count >= 3 {
                let name = String(parts[0])
                let image = String(parts[1])
                let status = String(parts[2])
                let marker = status.contains("Up") ? "●" : "○"
                let tag = configured.contains(name) ? " [configured]" : ""
                out += "  \(marker) \(name)\(tag)\n    Image: \(image)\n    Status: \(status)\n\n"
            }
        }
        return out
    }

    private static func logs(container: String?, lines: Int?) async throws -> String {
        let name = container ?? "twinprime"
        let n = lines ?? 50
        let (result, _) = try await ssh("docker logs --tail \(n) \(name)")
        return result
    }

    private static func start(container: String?) async throws -> String {
        let name = container ?? "twinprime"
        let (_, ok) = try await ssh("docker start \(name)")
        return ok == 0 ? "Container \(name) started" : "Failed to start \(name)"
    }

    private static func stop(container: String?) async throws -> String {
        let name = container ?? "twinprime"
        let (_, ok) = try await ssh("docker stop \(name)")
        return ok == 0 ? "Container \(name) stopped" : "Failed to stop \(name)"
    }

    // MARK: - Service Management

    private static func getServiceEndpoint(config: Config, service: Config.Service) -> String {
        // Get host IP from first host (assumes single-host setup)
        let hostIP = config.hosts.values.first?.fallbackIP ?? "192.168.1.159"
        return "http://\(hostIP):\(service.port)"
    }

    private static func serviceStatus(service serviceName: String?) async throws -> String {
        let config = try loadConfig()
        guard let services = config.services, !services.isEmpty else {
            return "No services configured.\n\nAdd services to ~/.dgx/config.json under \"services\" key."
        }

        // If no service specified, list all
        if serviceName == nil {
            var lines: [String] = ["## Services"]
            lines.append("")
            for (name, svc) in services.sorted(by: { $0.key < $1.key }) {
                let (procOut, _) = try await ssh("docker exec \(svc.container) pgrep -f '\(svc.process)' 2>/dev/null || echo ''")
                let running = !procOut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let status = running ? "🟢" : "🔴"
                let desc = svc.description ?? svc.container
                lines.append("\(status) **\(name)**: \(desc)")
            }
            lines.append("")
            lines.append("Use `dgx_service_status service:<name>` for details")
            return lines.joined(separator: "\n")
        }

        // Specific service status
        guard let svc = services[serviceName!] else {
            let available = services.keys.sorted().joined(separator: ", ")
            return "❌ Unknown service: \(serviceName!)\n\nAvailable: \(available)"
        }

        let endpoint = getServiceEndpoint(config: config, service: svc)
        var lines: [String] = []

        // Check if container is running
        let (containerOut, _) = try await ssh("docker ps --filter name=\(svc.container) --format '{{.Status}}'")
        let containerRunning = !containerOut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !containerRunning {
            lines.append("## \(serviceName!) Status")
            lines.append("")
            lines.append("**Status:** 🔴 Container stopped")
            lines.append("**Container:** \(svc.container)")
            lines.append("")
            lines.append("Run `dgx_service_start service:\(serviceName!)` to start")
            return lines.joined(separator: "\n")
        }

        // Check if process is running
        let (procOut, _) = try await ssh("docker exec \(svc.container) pgrep -f '\(svc.process)' 2>/dev/null || echo ''")
        let processRunning = !procOut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !processRunning {
            lines.append("## \(serviceName!) Status")
            lines.append("")
            lines.append("**Status:** 🟡 Container running, service stopped")
            lines.append("**Container:** \(svc.container)")
            lines.append("")
            lines.append("Run `dgx_service_start service:\(serviceName!)` to start")
            return lines.joined(separator: "\n")
        }

        // Try health endpoint if configured
        if let healthPath = svc.health {
            let (healthOut, healthOk) = try await ssh("curl -s \(endpoint)\(healthPath) 2>/dev/null || echo '{}'")

            lines.append("## \(serviceName!) Status")
            lines.append("")

            if healthOk == 0, let healthData = try? JSONSerialization.jsonObject(with: Data(healthOut.utf8)) as? [String: Any] {
                lines.append("**Status:** 🟢 Running")
                // Show any useful health data
                for (key, value) in healthData.sorted(by: { $0.key < $1.key }) {
                    if key == "gpu_memory_allocated_mb", let mb = value as? Double {
                        lines.append("**GPU Memory:** \(String(format: "%.1f", mb / 1000)) GB")
                    } else if let strVal = value as? String {
                        lines.append("**\(key.capitalized):** \(strVal)")
                    } else if let intVal = value as? Int {
                        lines.append("**\(key.capitalized):** \(intVal)")
                    }
                }
            } else {
                lines.append("**Status:** 🟡 Starting...")
            }
        } else {
            lines.append("## \(serviceName!) Status")
            lines.append("")
            lines.append("**Status:** 🟢 Running")
        }

        if let desc = svc.description {
            lines.append("**Description:** \(desc)")
        }
        lines.append("**Container:** \(svc.container)")
        lines.append("**Endpoint:** \(endpoint)")

        return lines.joined(separator: "\n")
    }

    private static func serviceStart(service serviceName: String) async throws -> String {
        let config = try loadConfig()
        guard let services = config.services, let svc = services[serviceName] else {
            let available = config.services?.keys.sorted().joined(separator: ", ") ?? "none"
            return "❌ Unknown service: \(serviceName)\n\nAvailable: \(available)"
        }

        let endpoint = getServiceEndpoint(config: config, service: svc)
        var lines: [String] = []

        // Ensure container is running
        let (containerOut, _) = try await ssh("docker ps --filter name=\(svc.container) --format '{{.Status}}'")
        if containerOut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let (_, startOk) = try await ssh("docker start \(svc.container)")
            if startOk != 0 {
                return "❌ Failed to start container \(svc.container)"
            }
            lines.append("✓ Started container \(svc.container)")
        }

        // Check if already running
        let (procOut, _) = try await ssh("docker exec \(svc.container) pgrep -f '\(svc.process)' 2>/dev/null || echo ''")
        if !procOut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "✓ \(serviceName) already running\n\nEndpoint: \(endpoint)"
        }

        // Start the service
        let startCmd = "docker exec -d \(svc.container) bash -c '\(svc.startCmd)'"
        let (_, ok) = try await ssh(startCmd)

        if ok != 0 {
            return "❌ Failed to start \(serviceName)"
        }

        lines.append("✓ Starting \(serviceName)...")
        if let desc = svc.description {
            lines.append("")
            lines.append("**Service:** \(desc)")
        }
        lines.append("")
        lines.append("Use `dgx_service_status service:\(serviceName)` to check when ready")
        lines.append("**Endpoint:** \(endpoint)")

        return lines.joined(separator: "\n")
    }

    private static func serviceStop(service serviceName: String) async throws -> String {
        let config = try loadConfig()
        guard let services = config.services, let svc = services[serviceName] else {
            let available = config.services?.keys.sorted().joined(separator: ", ") ?? "none"
            return "❌ Unknown service: \(serviceName)\n\nAvailable: \(available)"
        }

        // Kill the process
        let (_, ok) = try await ssh("docker exec \(svc.container) pkill -f '\(svc.process)' 2>/dev/null; echo done")

        if ok == 0 {
            return "✓ \(serviceName) stopped\n\nContainer \(svc.container) still running (use `dgx_stop` to stop container)"
        } else {
            return "⚠️ Service may not have been running"
        }
    }

    private static func exec(command: String, container: String?) async throws -> String {
        let config = try loadConfig()
        let containerName = container ?? "twinprime"

        // Find workdir from projects or container config
        var workdir = "/workspace"
        for proj in config.projects.values {
            if proj.container == containerName {
                workdir = proj.remote
                break
            }
        }
        if workdir == "/workspace", let c = config.containers[containerName] {
            workdir = c.workdir
        }

        // Escape for: ssh host 'docker exec -w dir container bash -c "command"'
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")

        let (result, _) = try await ssh("docker exec -w \(workdir) \(containerName) bash -c \"\(escaped)\"")
        return result
    }

    private static func sync(direction: String, project projectName: String?) async throws -> String {
        let config = try loadConfig()
        let host = try getHost()
        var state = loadState()

        // Use lastProject if none specified
        let resolvedProjectName: String
        if let projectName = projectName {
            resolvedProjectName = projectName
        } else if let lastProject = state.lastProject {
            resolvedProjectName = lastProject
        } else {
            let available = config.projects.keys.joined(separator: ", ")
            return "Project name required. Available: \(available)"
        }

        guard let project = config.projects[resolvedProjectName] else {
            let available = config.projects.keys.joined(separator: ", ")
            return "Project '\(resolvedProjectName)' not found. Available: \(available)"
        }

        let projectName = resolvedProjectName

        let excludes = project.exclude.map { "--exclude='\($0)'" }.joined(separator: " ")
        // Sync to ~/{project_name} on host - container volume mount maps this to container path
        let hostPath = "~/\(projectName)"
        var out = ""

        // Validate: Check that host directory exists and is user-owned
        if direction == "push" {
            let (dirCheck, _) = try await ssh("stat -c '%U' \(hostPath) 2>/dev/null || echo 'NOT_FOUND'")
            let owner = dirCheck.trimmingCharacters(in: .whitespacesAndNewlines)

            if owner == "NOT_FOUND" {
                var err = "❌ Host directory '\(hostPath)' does not exist.\n\n"
                err += "**Setup required:**\n"
                err += "The container needs to be created with the correct volume mount.\n\n"
                err += "Option 1: Use dgx_container_create (recommended)\n"
                err += "  - First add container to config: dgx_config_add_container\n"
                err += "  - Then create it: dgx_container_create container:\(project.container)\n\n"
                err += "Option 2: Manual setup\n"
                err += "  1. Create directory: ssh \(host) 'mkdir -p \(hostPath)'\n"
                err += "  2. Recreate container with mount: -v \(hostPath):\(project.remote)"
                return err
            }

            // Get current user on host to verify ownership
            let (currentUser, _) = try await ssh("whoami")
            let expectedUser = currentUser.trimmingCharacters(in: .whitespacesAndNewlines)
            if owner != expectedUser && owner != "root" {
                out += "⚠️ Warning: '\(hostPath)' owned by '\(owner)', expected '\(expectedUser)'\n"
            } else if owner == "root" {
                var err = "❌ Host directory '\(hostPath)' is owned by root.\n\n"
                err += "This usually happens when Docker created the directory.\n\n"
                err += "**Fix:** Run on DGX: sudo chown -R \(expectedUser):\(expectedUser) \(hostPath)"
                return err
            }
        }

        if direction == "push" {
            out += "Pushing \(projectName) to DGX...\n"
            let (result, _) = try await shell("rsync -avz \(excludes) \(project.local)/ \(host):\(hostPath)/")
            out += result
        } else {
            // Pull: if results field is set, only pull that subdirectory; otherwise pull whole project
            if let resultsDir = project.results {
                out += "Pulling \(resultsDir)/ from \(projectName)...\n"
                let (result, _) = try await shell("rsync -avz \(host):\(hostPath)/\(resultsDir)/ \(project.local)/\(resultsDir)/")
                out += result
            } else {
                out += "Pulling \(projectName) from DGX...\n"
                let (result, _) = try await shell("rsync -avz \(excludes) \(host):\(hostPath)/ \(project.local)/")
                out += result
            }
        }

        // Update state
        if state.projects[projectName] == nil {
            state.projects[projectName] = State.ProjectState()
        }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        if direction == "push" {
            state.projects[projectName]?.lastPush = timestamp
        } else {
            state.projects[projectName]?.lastPull = timestamp
        }
        // Remember this project for next time
        state.lastProject = projectName
        try saveState(state)

        out += "\nDone: \(direction) complete (using project: \(projectName))"
        return out
    }

    private static func run(command: String, project projectName: String?) async throws -> String {
        let config = try loadConfig()

        // Require project name
        guard let projectName = projectName, let project = config.projects[projectName] else {
            let available = config.projects.keys.joined(separator: ", ")
            return "Project name required. Available: \(available)"
        }

        var out = "=== Running on DGX Spark ===\n\n"

        // 1. Check container
        out += "1. Checking container...\n"
        let container = project.container
        let (statusOut, statusOk) = try await ssh("docker inspect \(container) --format '{{.State.Status}}'")
        if statusOk != 0 {
            return out + "   Container '\(container)' not found"
        }
        if statusOut.trimmingCharacters(in: .whitespacesAndNewlines) != "running" {
            out += "   Starting container...\n"
            let _ = try await ssh("docker start \(container)")
        } else {
            out += "   Container running\n"
        }

        // 2. Sync code
        out += "\n2. Syncing code...\n"
        let syncResult = try await sync(direction: "push", project: projectName)
        out += syncResult + "\n"

        // 3. Run command
        out += "\n3. Running: \(command)\n"
        out += String(repeating: "-", count: 40) + "\n"
        let execResult = try await exec(command: command, container: container)
        out += execResult + "\n"
        out += String(repeating: "-", count: 40) + "\n"

        // 4. Sync results
        out += "\n4. Syncing results...\n"
        let pullResult = try await sync(direction: "pull", project: projectName)
        out += pullResult + "\n"

        out += "\n=== Complete ==="
        return out
    }

    private static func checkUpdates() async throws -> String {
        let config = try loadConfig()
        var out = "=== Checking for NGC Updates ===\n\n"

        for (name, container) in config.containers {
            guard container.image.contains("nvcr.io") else { continue }

            let parts = container.image.split(separator: ":")
            guard parts.count == 2 else { continue }
            let imageBase = String(parts[0])
            let currentTag = String(parts[1])

            out += "Container: \(name)\n  Current: \(currentTag)\n"

            // Get image date
            let (created, _) = try await ssh("docker inspect \(container.image) --format '{{.Created}}'")
            if !created.isEmpty {
                out += "  Date: \(String(created.prefix(10)))\n"
            }

            // Parse YY.MM-py3 format and check for newer
            let tagParts = currentTag.replacingOccurrences(of: "-py3", with: "").split(separator: ".")
            if tagParts.count == 2, let year = Int(tagParts[0]), let month = Int(tagParts[1]) {
                var newerTags: [String] = []

                for i in 1...3 {
                    var nextMonth = month + i
                    var nextYear = year
                    if nextMonth > 12 {
                        nextMonth -= 12
                        nextYear += 1
                    }
                    let nextTag = String(format: "%02d.%02d-py3", nextYear, nextMonth)

                    let (_, ok) = try await ssh("docker manifest inspect \(imageBase):\(nextTag) >/dev/null 2>&1")
                    if ok == 0 {
                        newerTags.append(nextTag)
                    }
                }

                if !newerTags.isEmpty {
                    out += "  Available updates: \(newerTags.joined(separator: ", "))\n"
                    out += "  Latest: \(newerTags.last!)\n"
                    let releaseTag = newerTags.last!.replacingOccurrences(of: "-py3", with: "").replacingOccurrences(of: ".", with: "-")
                    out += "  Release notes: https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/rel-\(releaseTag).html\n"
                    out += "  → Use WebFetch to summarize changes before upgrading\n"
                } else {
                    out += "  Status: Up to date\n"
                }
            }
            out += "\n"
        }
        return out
    }

    private static func upgrade(container containerName: String?, confirm: Bool) async throws -> String {
        let config = try loadConfig()
        let name = containerName ?? "twinprime"

        guard let container = config.containers[name] else {
            return "Container '\(name)' not found in config"
        }

        let parts = container.image.split(separator: ":")
        guard parts.count == 2 else { return "Invalid image format" }
        let imageBase = String(parts[0])
        let currentTag = String(parts[1])

        // Find latest tag
        let tagParts = currentTag.replacingOccurrences(of: "-py3", with: "").split(separator: ".")
        guard tagParts.count == 2, let year = Int(tagParts[0]), let month = Int(tagParts[1]) else {
            return "Can't parse current tag: \(currentTag)"
        }

        var latestTag = currentTag
        for i in 1...6 {
            var nextMonth = month + i
            var nextYear = year
            if nextMonth > 12 {
                nextMonth -= 12
                nextYear += 1
            }
            let nextTag = String(format: "%02d.%02d-py3", nextYear, nextMonth)
            let (_, ok) = try await ssh("docker manifest inspect \(imageBase):\(nextTag) >/dev/null 2>&1")
            if ok == 0 {
                latestTag = nextTag
            }
        }

        if latestTag == currentTag {
            return "Already on latest version: \(currentTag)"
        }

        let newImage = "\(imageBase):\(latestTag)"
        var out = "Upgrade available:\n  Current: \(container.image)\n  New:     \(newImage)\n\n"

        if !confirm {
            return out + "Pass confirm: true to proceed with upgrade"
        }

        // Pull
        out += "1. Pulling new image...\n"
        let (pullOut, _) = try await ssh("docker pull \(newImage)")
        out += pullOut + "\n"

        // Stop and remove
        out += "\n2. Stopping old container...\n"
        let _ = try await ssh("docker stop \(name)")
        let _ = try await ssh("docker rm \(name)")

        // Create new
        out += "\n3. Creating new container...\n"
        var mountSrc: String?
        var mountDst: String?
        for (projName, proj) in config.projects {
            if proj.container == name {
                mountSrc = "~/\(projName)"
                mountDst = proj.remote
                break
            }
        }

        let mountFlag = mountSrc != nil && mountDst != nil ? "-v \(mountSrc!):\(mountDst!)" : ""
        let cmd = """
            docker run -d --runtime=nvidia --gpus=all \
            --name \(name) \(mountFlag) \
            --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 \
            \(newImage) tail -f /dev/null
            """
        let (createOut, createOk) = try await ssh(cmd)
        if createOk != 0 {
            return out + "Failed to create container: \(createOut)"
        }

        // Install deps
        out += "\n4. Installing dependencies...\n"
        let _ = try await ssh("docker exec \(name) pip install uv")
        if let mountDst = mountDst {
            let _ = try await ssh("docker exec -w \(mountDst) \(name) uv sync")
        }

        out += "\n=== Upgrade complete ===\n"
        out += "Update your config to: image: \(newImage)"
        return out
    }

    // MARK: - Background Jobs

    private static let jobsDir = "/workspace/.jobs"

    // MARK: - Pre-flight GPU Check

    struct PreflightResult {
        let canProceed: Bool
        let warnings: [String]
        let gpuUtil: Int
        let gpuMemUsedGB: Double
        let gpuMemTotalGB: Double
        let runningJobs: Int
    }

    /// Check GPU status before starting a job
    private static func preflightCheck(container: String?) async throws -> PreflightResult {
        var warnings: [String] = []

        // Check GPU utilization and memory
        let (gpuInfo, gpuOk) = try await ssh("nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits")

        var gpuUtil = 0
        var gpuMemUsed: Double = 0
        var gpuMemTotal: Double = 128.0  // Default for GB10

        if gpuOk == 0 {
            let parts = gpuInfo.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 3 {
                gpuUtil = Int(parts[0]) ?? 0
                gpuMemUsed = (Double(parts[1]) ?? 0) / 1024.0  // MiB to GB
                gpuMemTotal = (Double(parts[2]) ?? 128000) / 1024.0
            }

            // Check utilization
            if gpuUtil > 50 {
                warnings.append("⚠️  GPU utilization is \(gpuUtil)% - another process may be using it")
            }

            // Check memory
            let memUsedPct = (gpuMemUsed / gpuMemTotal) * 100
            if memUsedPct > 50 {
                warnings.append("⚠️  GPU memory is \(String(format: "%.0f", memUsedPct))% used (\(String(format: "%.1f", gpuMemUsed))/\(String(format: "%.0f", gpuMemTotal)) GB)")
            }
        }

        // Check for running jobs
        let containerName = container ?? "twinprime"
        let (runningStatus, _) = try await ssh("docker exec \(containerName) bash -c 'grep -l running \(jobsDir)/*.status 2>/dev/null | wc -l'")
        let runningJobs = Int(runningStatus.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        if runningJobs > 0 {
            warnings.append("⚠️  \(runningJobs) job(s) already running - resources may be contested")
        }

        return PreflightResult(
            canProceed: true,  // We warn but don't block
            warnings: warnings,
            gpuUtil: gpuUtil,
            gpuMemUsedGB: gpuMemUsed,
            gpuMemTotalGB: gpuMemTotal,
            runningJobs: runningJobs
        )
    }

    private static func jobStart(command: String, name: String?, container: String?, workdir: String?) async throws -> String {
        let containerName = container ?? "twinprime"
        let dir = workdir ?? "/workspace"

        // Pre-flight GPU check
        let preflight = try await preflightCheck(container: containerName)

        // Generate job ID: timestamp-based for sorting
        let jobId = "job_\(Int(Date().timeIntervalSince1970))"

        // Ensure jobs directory exists
        let _ = try await ssh("docker exec \(containerName) mkdir -p \(jobsDir)")

        // Create the job script that handles logging and status
        // PYTHONUNBUFFERED=1 ensures real-time log output for Python scripts
        // .start file records start timestamp for elapsed time calculation
        let script = """
            cd \(dir) && \\
            echo '\(command)' > \(jobsDir)/\(jobId).cmd && \\
            echo 'running' > \(jobsDir)/\(jobId).status && \\
            date +%s > \(jobsDir)/\(jobId).start && \\
            echo $$ > \(jobsDir)/\(jobId).pid && \\
            (PYTHONUNBUFFERED=1 \(command)) > \(jobsDir)/\(jobId).log 2>&1; \\
            echo $? > \(jobsDir)/\(jobId).exit; \\
            date +%s > \(jobsDir)/\(jobId).end && \\
            echo 'completed' > \(jobsDir)/\(jobId).status
            """

        // Run detached with nohup
        let dockerCmd = "docker exec -d \(containerName) bash -c \"\(script.replacingOccurrences(of: "\"", with: "\\\""))\""
        let (_, ok) = try await ssh(dockerCmd)

        if ok != 0 {
            return "Failed to start job"
        }

        // Update local job cache for DGXDash
        addRunningJobToCache(jobId: jobId, name: name, command: command, container: containerName, workdir: dir)

        var out = "Job started: \(jobId)\n"
        out += "Command: \(command)\n"
        out += "Container: \(containerName)\n"
        out += "Workdir: \(dir)\n"

        // Show GPU status
        out += "GPU: \(preflight.gpuUtil)% util | \(String(format: "%.1f", preflight.gpuMemUsedGB))/\(String(format: "%.0f", preflight.gpuMemTotalGB)) GB\n"

        // Show pre-flight warnings if any
        if !preflight.warnings.isEmpty {
            out += "\n"
            for warning in preflight.warnings {
                out += "\(warning)\n"
            }
        }

        out += "\nMonitor with:\n"
        out += "  dgx_jobs - check status\n"
        out += "  dgx_job_log(\"\(jobId)\") - view output\n"
        out += "  dgx_telemetry - watch GPU/memory"
        return out
    }

    private static func jobsList(container: String?, limit: Int?) async throws -> String {
        let containerName = container ?? "twinprime"
        let maxJobs = limit ?? 5

        // BATCHED: Single SSH call to get all job data
        // Output format: job_id|exit_code|status|cmd|start|end|duration|now|has_errors
        let batchScript = """
            now=$(date +%s)
            for f in $(ls -t \(jobsDir)/*.status 2>/dev/null | head -n \(maxJobs)); do
                job=$(basename "$f" .status)
                exit_code=$(cat \(jobsDir)/$job.exit 2>/dev/null || echo "-")
                status=$(cat \(jobsDir)/$job.status 2>/dev/null || echo "unknown")
                cmd=$(cat \(jobsDir)/$job.cmd 2>/dev/null | head -c 60 || echo "?")
                start=$(cat \(jobsDir)/$job.start 2>/dev/null || echo "0")
                end=$(cat \(jobsDir)/$job.end 2>/dev/null || echo "0")
                if [ "$start" != "0" ] && [ "$end" != "0" ]; then
                    duration=$((end - start))
                elif [ "$start" != "0" ]; then
                    duration=$((now - start))
                else
                    duration=0
                fi
                has_err="-"
                if [ "$exit_code" != "-" ] && [ "$exit_code" != "0" ]; then
                    if grep -qE 'Traceback|Error|OOM|Killed|CUDA' \(jobsDir)/$job.log 2>/dev/null; then
                        has_err="1"
                    fi
                fi
                echo "$job|$exit_code|$status|$cmd|$start|$end|$duration|$now|$has_err"
            done
            """

        let (output, ok) = try await ssh("docker exec \(containerName) bash -c '\(batchScript.replacingOccurrences(of: "'", with: "'\"'\"'"))'")
        if ok != 0 || output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Update cache with empty state
            updateJobCacheFromList(jobs: [], container: containerName)
            return "No jobs found"
        }

        var out = "=== Background Jobs ===\n\n"

        // Collect jobs for cache update
        // Format: job_id|exit_code|status|cmd|start|end|duration|now|has_errors
        var parsedJobs: [(id: String, exitCode: String, status: String, cmd: String, start: String, end: String, duration: Int, now: String, hasErrors: Bool)] = []

        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "|", omittingEmptySubsequences: false).map { String($0) }
            guard parts.count >= 9 else { continue }

            let jobId = parts[0]
            let exitCode = parts[1]
            var actualStatus = parts[2]
            let cmd = parts[3]
            let startStr = parts[4]
            let endStr = parts[5]
            let durationVal = Int(parts[6]) ?? 0
            let nowStr = parts[7]
            let hasErrorsStr = parts[8]

            let hasExitFile = exitCode != "-"
            let hasErrors = hasErrorsStr == "1"

            // Collect for cache
            parsedJobs.append((
                id: jobId,
                exitCode: exitCode,
                status: actualStatus,
                cmd: cmd,
                start: startStr,
                end: endStr,
                duration: durationVal,
                now: nowStr,
                hasErrors: hasErrors
            ))

            // Determine actual status from exit code
            if hasExitFile {
                actualStatus = exitCode == "0" ? "completed" : "failed"
            }

            // Calculate time string using pre-calculated duration
            var timeStr = ""
            if durationVal > 0 {
                if hasExitFile {
                    timeStr = " (\(formatDuration(durationVal)))"
                } else if actualStatus == "running" {
                    timeStr = " (running \(formatDuration(durationVal)))"
                }
            }

            let icon: String
            switch actualStatus {
            case "running": icon = "🔄"
            case "completed": icon = "✅"
            case "failed": icon = hasErrors ? "🔴" : "❌"
            case "killed": icon = "⛔"
            case "stale": icon = "⚠️"
            default: icon = "❓"
            }

            let cmdShort = cmd.trimmingCharacters(in: .whitespacesAndNewlines).prefix(50)
            var statusLine = actualStatus
            if actualStatus == "failed" {
                statusLine = "failed (exit \(exitCode))"
                if hasErrors {
                    statusLine += " - errors detected, use dgx_job_log to see details"
                }
            }
            out += "\(icon) \(jobId)\(timeStr)\n   Status: \(statusLine)\n   Command: \(cmdShort)\n\n"
        }

        // Update local job cache for DGXDash (authoritative sync)
        updateJobCacheFromList(jobs: parsedJobs, container: containerName)

        return out
    }

    /// Format duration in human-readable format
    private static func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let mins = seconds / 60
            let secs = seconds % 60
            return "\(mins)m \(secs)s"
        } else {
            let hours = seconds / 3600
            let mins = (seconds % 3600) / 60
            return "\(hours)h \(mins)m"
        }
    }

    // MARK: - Error Detection

    /// Known error patterns to detect in job output
    private static let errorPatterns: [(pattern: String, severity: String, description: String)] = [
        ("CUDA out of memory", "critical", "GPU memory exhausted"),
        ("torch.cuda.OutOfMemoryError", "critical", "PyTorch GPU OOM"),
        ("RuntimeError:", "error", "Python runtime error"),
        ("Traceback \\(most recent call last\\)", "error", "Python exception traceback"),
        ("MemoryError", "critical", "System memory exhausted"),
        ("Killed", "critical", "Process killed (likely OOM)"),
        ("OOM", "critical", "Out of memory"),
        ("KeyboardInterrupt", "warning", "User interrupted"),
        ("ModuleNotFoundError", "error", "Missing Python module"),
        ("ImportError", "error", "Import failed"),
        ("FileNotFoundError", "error", "File not found"),
        ("PermissionError", "error", "Permission denied"),
        ("NCCL error", "critical", "GPU communication error"),
        ("cuDNN error", "error", "GPU library error"),
        ("AssertionError", "error", "Assertion failed"),
        ("ValueError", "warning", "Invalid value"),
        ("TypeError", "warning", "Type mismatch"),
        ("ZeroDivisionError", "error", "Division by zero"),
        ("Segmentation fault", "critical", "Memory access violation"),
        ("core dumped", "critical", "Process crashed"),
    ]

    /// Detected error in job output
    struct DetectedError: Equatable {
        let pattern: String
        let severity: String
        let description: String
        let line: String
        let lineNumber: Int
    }

    /// Scan text for known error patterns
    private static func detectErrors(in text: String) -> [DetectedError] {
        var errors: [DetectedError] = []
        let lines = text.components(separatedBy: .newlines)

        for (lineNum, line) in lines.enumerated() {
            for (pattern, severity, desc) in errorPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil {
                    let error = DetectedError(
                        pattern: pattern,
                        severity: severity,
                        description: desc,
                        line: String(line.prefix(100)),
                        lineNumber: lineNum + 1
                    )
                    // Avoid duplicate patterns on same line
                    if !errors.contains(where: { $0.lineNumber == error.lineNumber && $0.pattern == error.pattern }) {
                        errors.append(error)
                    }
                }
            }
        }
        return errors
    }

    /// Format detected errors for display
    private static func formatErrors(_ errors: [DetectedError]) -> String {
        guard !errors.isEmpty else { return "" }

        var out = "⚠️  DETECTED ISSUES (\(errors.count)):\n"

        // Group by severity
        let critical = errors.filter { $0.severity == "critical" }
        let errorLevel = errors.filter { $0.severity == "error" }
        let warnings = errors.filter { $0.severity == "warning" }

        if !critical.isEmpty {
            out += "  🔴 CRITICAL:\n"
            for e in critical.prefix(3) {
                out += "     Line \(e.lineNumber): \(e.description)\n"
                out += "     → \(e.line.prefix(80))\n"
            }
            if critical.count > 3 {
                out += "     ... and \(critical.count - 3) more\n"
            }
        }

        if !errorLevel.isEmpty {
            out += "  🟠 ERRORS:\n"
            for e in errorLevel.prefix(3) {
                out += "     Line \(e.lineNumber): \(e.description)\n"
            }
            if errorLevel.count > 3 {
                out += "     ... and \(errorLevel.count - 3) more\n"
            }
        }

        if !warnings.isEmpty {
            out += "  🟡 WARNINGS: \(warnings.count) issue(s)\n"
        }

        out += "\n"
        return out
    }

    // MARK: - Metrics Extraction

    /// Known metrics patterns to extract from job output
    private static let metricsPatterns: [(name: String, pattern: String, unit: String)] = [
        ("Selection bias", "Selection bias:\\s*([\\d.]+)%", "%"),
        ("Total runtime", "Total runtime:\\s*([\\d.]+)s", "s"),
        ("K", "K\\s*=\\s*([\\d,]+)", ""),
        ("Phase 1", "Phase 1.*?([\\d.]+)s", "s"),
        ("Phase 2", "Phase 2.*?([\\d.]+)s", "s"),
        ("Phase 3", "Phase 3.*?([\\d.]+)s", "s"),
        ("Fused kernel", "fused computation:\\s*([\\d.]+)s", "s"),
        ("GPU util", "GPU:\\s*(\\d+)%\\s*util", "%"),
        ("Memory", "Memory.*?([\\d.]+)\\s*GB", " GB"),
        ("PC ω", "PC composite ω\\s*=\\s*([\\d.]+)", ""),
        ("CC ω", "CC composite ω\\s*=\\s*([\\d.]+)", ""),
    ]

    /// Extracted metric from job output
    struct ExtractedMetric {
        let name: String
        let value: String
        let unit: String
    }

    /// Extract metrics from text
    private static func extractMetrics(from text: String) -> [ExtractedMetric] {
        var metrics: [ExtractedMetric] = []

        for (name, pattern, unit) in metricsPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let valueRange = Range(match.range(at: 1), in: text) {
                let value = String(text[valueRange])
                metrics.append(ExtractedMetric(name: name, value: value, unit: unit))
            }
        }
        return metrics
    }

    /// Format extracted metrics for display
    private static func formatMetrics(_ metrics: [ExtractedMetric]) -> String {
        guard !metrics.isEmpty else { return "" }

        var out = "📊 METRICS:\n"

        // Find the key result first
        if let bias = metrics.first(where: { $0.name == "Selection bias" }) {
            out += "   ★ Selection bias: \(bias.value)\(bias.unit)\n"
        }

        // Show K and runtime
        if let k = metrics.first(where: { $0.name == "K" }) {
            out += "   K = \(k.value)\n"
        }
        if let runtime = metrics.first(where: { $0.name == "Total runtime" }) {
            out += "   Runtime: \(runtime.value)\(runtime.unit)\n"
        }

        // Show phase timings if present
        let phases = metrics.filter { $0.name.starts(with: "Phase") || $0.name == "Fused kernel" }
        if !phases.isEmpty {
            out += "   Phases: "
            out += phases.map { "\($0.name): \($0.value)\($0.unit)" }.joined(separator: " | ")
            out += "\n"
        }

        out += "\n"
        return out
    }

    private static func jobLog(jobId: String, container: String?, lines: Int?) async throws -> String {
        let containerName = container ?? "twinprime"
        let n = lines ?? 50

        let logFile = "\(jobsDir)/\(jobId).log"

        // Check if job exists
        let (_, exists) = try await ssh("docker exec \(containerName) test -f \(logFile)")
        if exists != 0 {
            return "Job not found: \(jobId)"
        }

        // Reliable status detection using .exit file
        let (_, exitExists) = try await ssh("docker exec \(containerName) test -f \(jobsDir)/\(jobId).exit")
        let status: String
        if exitExists == 0 {
            // Job has completed - get exit code
            let (exitCode, _) = try await ssh("docker exec \(containerName) cat \(jobsDir)/\(jobId).exit")
            let code = exitCode.trimmingCharacters(in: .whitespacesAndNewlines)
            status = code == "0" ? "completed (exit 0)" : "failed (exit \(code))"
        } else {
            status = "running"
        }

        var out = "=== Job: \(jobId) ===\n"
        out += "Status: \(status)\n\n"

        // Get log content
        let tailCmd = n == 0 ? "cat" : "tail -n \(n)"
        let (log, _) = try await ssh("docker exec \(containerName) \(tailCmd) \(logFile)")

        // Detect errors in log output
        let errors = detectErrors(in: log)
        if !errors.isEmpty {
            out += formatErrors(errors)
        }

        // Extract metrics from log (for completed jobs)
        if status.contains("completed") {
            let metrics = extractMetrics(from: log)
            if !metrics.isEmpty {
                out += formatMetrics(metrics)
            }

            // Suggest result sync for successful jobs
            let state = loadState()
            let projectHint = state.lastProject ?? "<project-name>"
            out += "💡 TIP: Results may need syncing back to local:\n"
            out += "   dgx_sync(direction: \"pull\", project: \"\(projectHint)\")\n\n"
        }

        out += log

        return out
    }

    private static func jobKill(jobId: String, container: String?) async throws -> String {
        let containerName = container ?? "twinprime"

        // Get PID
        let (pid, ok) = try await ssh("docker exec \(containerName) cat \(jobsDir)/\(jobId).pid 2>/dev/null")
        if ok != 0 {
            return "Job not found: \(jobId)"
        }

        let pidNum = pid.trimmingCharacters(in: .whitespacesAndNewlines)

        // Kill the process tree
        let (_, killOk) = try await ssh("docker exec \(containerName) pkill -P \(pidNum); kill \(pidNum) 2>/dev/null")

        // Update status
        let _ = try await ssh("docker exec \(containerName) echo 'killed' > \(jobsDir)/\(jobId).status")

        // Update local job cache for DGXDash
        markJobKilledInCache(jobId: jobId)

        return killOk == 0 ? "Job \(jobId) killed" : "Job \(jobId) may already be finished"
    }

    // MARK: - Job Retry

    private static func jobRetry(jobId: String, container: String?) async throws -> String {
        let containerName = container ?? "twinprime"

        // Get the original command
        let (cmd, ok) = try await ssh("docker exec \(containerName) cat \(jobsDir)/\(jobId).cmd 2>/dev/null")
        if ok != 0 {
            return "Job not found: \(jobId)"
        }

        let command = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        if command.isEmpty || command == "?" {
            return "Cannot retry: original command not found"
        }

        // Start a new job with the same command (name not preserved on retry)
        let result = try await jobStart(command: command, name: nil, container: containerName, workdir: "/workspace")
        return "Retrying job \(jobId):\n\n\(result)"
    }

    // MARK: - Job Cleanup

    private static func jobClean(olderThanHours: Int?, container: String?, keepLast: Int?) async throws -> String {
        let containerName = container ?? "twinprime"
        let hours = olderThanHours ?? 24
        let keep = keepLast ?? 5

        // Get all job IDs sorted by time (newest first)
        let (files, ok) = try await ssh("docker exec \(containerName) bash -c 'ls -t \(jobsDir)/*.status 2>/dev/null || echo \"\"'")
        if ok != 0 || files.isEmpty {
            return "No jobs to clean"
        }

        let allJobs = files.split(separator: "\n").map { statusFile -> String in
            String(statusFile).replacingOccurrences(of: "\(jobsDir)/", with: "").replacingOccurrences(of: ".status", with: "")
        }

        // Get current timestamp
        let (nowStr, _) = try await ssh("docker exec \(containerName) date +%s")
        let now = Int(nowStr.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let cutoff = now - (hours * 3600)

        var removed = 0
        var kept = 0

        for (index, jobId) in allJobs.enumerated() {
            // Always keep the N most recent
            if index < keep {
                kept += 1
                continue
            }

            // Check job age
            let (startStr, startOk) = try await ssh("docker exec \(containerName) cat \(jobsDir)/\(jobId).start 2>/dev/null")
            if startOk == 0, let start = Int(startStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                if start < cutoff {
                    // Remove all files for this job
                    let _ = try await ssh("docker exec \(containerName) rm -f \(jobsDir)/\(jobId).* 2>/dev/null")
                    removed += 1
                } else {
                    kept += 1
                }
            }
        }

        return "Cleaned up \(removed) old jobs, kept \(kept) recent jobs"
    }

    // MARK: - Job Watch (with diff and GPU stats)

    private static func jobWatch(jobId: String, container: String?) async throws -> String {
        let containerName = container ?? "twinprime"
        let logFile = "\(jobsDir)/\(jobId).log"

        // Check if job exists
        let (_, exists) = try await ssh("docker exec \(containerName) test -f \(logFile)")
        if exists != 0 {
            return "Job not found: \(jobId)"
        }

        // Load state to get last read position
        var state = loadState()
        let lastPos = state.jobWatchState[jobId]?.lastBytePosition ?? 0

        // Get current file size
        let (sizeStr, _) = try await ssh("docker exec \(containerName) stat -c%s \(logFile) 2>/dev/null || echo 0")
        let currentSize = Int(sizeStr.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        // Get job status and time
        let (_, exitExists) = try await ssh("docker exec \(containerName) test -f \(jobsDir)/\(jobId).exit")
        let isRunning = exitExists != 0

        var timeStr = ""
        let (startStr, startOk) = try await ssh("docker exec \(containerName) cat \(jobsDir)/\(jobId).start 2>/dev/null")
        if startOk == 0, let start = Int(startStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
            if isRunning {
                let (nowStr, _) = try await ssh("docker exec \(containerName) date +%s")
                if let now = Int(nowStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    timeStr = "Elapsed: \(formatDuration(now - start))"
                }
            } else {
                let (endStr, endOk) = try await ssh("docker exec \(containerName) cat \(jobsDir)/\(jobId).end 2>/dev/null")
                if endOk == 0, let end = Int(endStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    timeStr = "Duration: \(formatDuration(end - start))"
                }
            }
        }

        var out = "=== Job Watch: \(jobId) ===\n"
        out += "Status: \(isRunning ? "🔄 running" : "✅ completed")"
        if !timeStr.isEmpty { out += " | \(timeStr)" }
        out += "\n"

        // Show GPU stats if running
        if isRunning {
            let (gpuInfo, gpuOk) = try await ssh("nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits")
            if gpuOk == 0 {
                let parts = gpuInfo.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 4 {
                    out += "GPU: \(parts[0])% util | \(parts[1])/\(parts[2]) MiB | \(parts[3])°C\n"
                }
            }
        } else {
            // Show metrics for completed jobs
            let (fullLog, _) = try await ssh("docker exec \(containerName) cat \(logFile)")
            let metrics = extractMetrics(from: fullLog)
            if !metrics.isEmpty {
                out += formatMetrics(metrics)
            }

            // Suggest result sync
            let syncState = loadState()
            let projectHint = syncState.lastProject ?? "<name>"
            out += "💡 TIP: Sync results with: dgx_sync(direction: \"pull\", project: \"\(projectHint)\")\n"
        }

        out += "\n"

        // Get new output since last check
        if currentSize > lastPos {
            let bytesToRead = currentSize - lastPos
            let (newContent, _) = try await ssh("docker exec \(containerName) tail -c \(bytesToRead) \(logFile)")
            if newContent.isEmpty {
                out += "(no new output)\n"
            } else {
                // Check for errors in new content
                let errors = detectErrors(in: newContent)
                if !errors.isEmpty {
                    out += formatErrors(errors)
                }
                out += "--- New output (\(bytesToRead) bytes) ---\n"
                out += newContent
                if !newContent.hasSuffix("\n") { out += "\n" }
                out += "--- End new output ---\n"
            }
        } else if lastPos == 0 {
            // First watch - show last 20 lines
            let (recent, _) = try await ssh("docker exec \(containerName) tail -n 20 \(logFile)")
            // Check for errors in recent content
            let errors = detectErrors(in: recent)
            if !errors.isEmpty {
                out += formatErrors(errors)
            }
            out += "--- Recent output (last 20 lines) ---\n"
            out += recent
            if !recent.hasSuffix("\n") { out += "\n" }
            out += "--- End recent output ---\n"
        } else {
            out += "(no new output since last check)\n"
        }

        // Update state with new position
        state.jobWatchState[jobId] = State.JobWatchState(
            lastBytePosition: currentSize,
            lastCheckTime: ISO8601DateFormatter().string(from: Date())
        )
        try saveState(state)

        return out
    }

    // MARK: - Job Comparison

    private static func jobCompare(job1: String, job2: String, container: String?) async throws -> String {
        let containerName = container ?? "twinprime"

        // Get logs for both jobs (tail only - metrics are at the end)
        let (log1, ok1) = try await ssh("docker exec \(containerName) tail -n 100 \(jobsDir)/\(job1).log 2>/dev/null")
        let (log2, ok2) = try await ssh("docker exec \(containerName) tail -n 100 \(jobsDir)/\(job2).log 2>/dev/null")

        if ok1 != 0 {
            return "Job not found: \(job1)"
        }
        if ok2 != 0 {
            return "Job not found: \(job2)"
        }

        // Extract metrics from both
        let metrics1 = extractMetrics(from: log1)
        let metrics2 = extractMetrics(from: log2)

        if metrics1.isEmpty && metrics2.isEmpty {
            return "No metrics found in either job's output"
        }

        var out = "=== Job Comparison ===\n"
        out += "Job 1: \(job1)\n"
        out += "Job 2: \(job2)\n\n"

        // Create lookup for easy comparison
        let dict1 = Dictionary(uniqueKeysWithValues: metrics1.map { ($0.name, $0) })
        let dict2 = Dictionary(uniqueKeysWithValues: metrics2.map { ($0.name, $0) })

        // All unique metric names
        let allNames = Set(metrics1.map { $0.name } + metrics2.map { $0.name })

        // Format comparison table
        out += "Metric             |      Job 1      |      Job 2      |    Δ Change\n"
        out += String(repeating: "-", count: 70) + "\n"

        for name in allNames.sorted() {
            let m1 = dict1[name]
            let m2 = dict2[name]

            let v1 = m1?.value ?? "-"
            let v2 = m2?.value ?? "-"
            let unit = m1?.unit ?? m2?.unit ?? ""

            // Try to compute delta for numeric values
            var delta = ""
            if let val1 = Double(v1.replacingOccurrences(of: ",", with: "")),
               let val2 = Double(v2.replacingOccurrences(of: ",", with: "")) {
                let diff = val2 - val1
                let pctChange = val1 != 0 ? (diff / val1) * 100 : 0
                if diff > 0 {
                    delta = "+\(String(format: "%.2f", diff))\(unit) (+\(String(format: "%.1f", pctChange))%)"
                } else if diff < 0 {
                    delta = "\(String(format: "%.2f", diff))\(unit) (\(String(format: "%.1f", pctChange))%)"
                } else {
                    delta = "same"
                }
            }

            // Pad strings manually for alignment
            let namePad = name.padding(toLength: 18, withPad: " ", startingAt: 0)
            let v1Pad = (v1 + unit).padding(toLength: 15, withPad: " ", startingAt: 0)
            let v2Pad = (v2 + unit).padding(toLength: 15, withPad: " ", startingAt: 0)
            out += "\(namePad) | \(v1Pad) | \(v2Pad) | \(delta)\n"
        }

        // Highlight key comparison
        if let bias1 = dict1["Selection bias"], let bias2 = dict2["Selection bias"],
           let b1 = Double(bias1.value), let b2 = Double(bias2.value) {
            out += "\n"
            let diff = b2 - b1
            if abs(diff) < 0.001 {
                out += "📊 Selection bias: essentially unchanged (\(String(format: "%.3f", diff))%)\n"
            } else if diff > 0 {
                out += "📊 Selection bias: increased by \(String(format: "%.3f", diff))%\n"
            } else {
                out += "📊 Selection bias: decreased by \(String(format: "%.3f", abs(diff)))%\n"
            }
        }

        return out
    }

    // MARK: - Job Statistics

    private static func jobStats(container: String?, limit: Int?) async throws -> String {
        let containerName = container ?? "twinprime"
        let maxJobs = limit ?? 20

        // BATCHED: Single SSH call to get all job data
        // Output format: job_id|exit_code|start|end|bias_line
        let batchScript = """
            for f in $(ls -t \(jobsDir)/*.status 2>/dev/null | head -n \(maxJobs)); do
                job=$(basename "$f" .status)
                exit_code=$(cat \(jobsDir)/$job.exit 2>/dev/null || echo "-")
                start=$(cat \(jobsDir)/$job.start 2>/dev/null || echo "-")
                end=$(cat \(jobsDir)/$job.end 2>/dev/null || echo "-")
                bias=$(grep -o 'Selection bias: [0-9.]*%' \(jobsDir)/$job.log 2>/dev/null | tail -1 || echo "-")
                echo "$job|$exit_code|$start|$end|$bias"
            done
            """

        let (output, ok) = try await ssh("docker exec \(containerName) bash -c '\(batchScript.replacingOccurrences(of: "'", with: "'\"'\"'"))'")
        if ok != 0 || output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No job history found"
        }

        var totalJobs = 0
        var successful = 0
        var failed = 0
        var runtimes: [Int] = []
        var selectionBiases: [Double] = []

        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "|", omittingEmptySubsequences: false).map { String($0) }
            guard parts.count >= 5 else { continue }

            totalJobs += 1
            let exitCode = parts[1]
            let startStr = parts[2]
            let endStr = parts[3]
            let biasStr = parts[4]

            // Count success/fail
            if exitCode != "-" {
                if exitCode == "0" {
                    successful += 1
                } else {
                    failed += 1
                }
            }

            // Calculate runtime
            if let start = Int(startStr), let end = Int(endStr) {
                let runtime = end - start
                if runtime > 0 {
                    runtimes.append(runtime)
                }
            }

            // Extract selection bias (format: "Selection bias: 2.941%")
            if biasStr != "-" {
                let numStr = biasStr.replacingOccurrences(of: "Selection bias: ", with: "")
                                    .replacingOccurrences(of: "%", with: "")
                if let biasValue = Double(numStr) {
                    selectionBiases.append(biasValue)
                }
            }
        }

        var out = "=== Job Statistics ===\n\n"
        out += "Jobs analyzed: \(totalJobs)\n"
        out += "  ✅ Successful: \(successful)\n"
        out += "  ❌ Failed: \(failed)\n"
        if totalJobs > 0 {
            let successRate = Double(successful) / Double(totalJobs) * 100
            out += "  📊 Success rate: \(String(format: "%.1f", successRate))%\n"
        }

        if !runtimes.isEmpty {
            out += "\nRuntime Statistics:\n"
            let avgRuntime = runtimes.reduce(0, +) / runtimes.count
            let minRuntime = runtimes.min()!
            let maxRuntime = runtimes.max()!
            out += "  Average: \(formatDuration(avgRuntime))\n"
            out += "  Fastest: \(formatDuration(minRuntime))\n"
            out += "  Slowest: \(formatDuration(maxRuntime))\n"
        }

        if !selectionBiases.isEmpty {
            out += "\nSelection Bias (from successful runs):\n"
            let avgBias = selectionBiases.reduce(0, +) / Double(selectionBiases.count)
            let minBias = selectionBiases.min()!
            let maxBias = selectionBiases.max()!
            out += "  Average: \(String(format: "%.4f", avgBias))%\n"
            out += "  Range: \(String(format: "%.4f", minBias))% - \(String(format: "%.4f", maxBias))%\n"
        }

        return out
    }

    // MARK: - Templates

    private static func templateSave(name: String, command: String, description: String?, project: String?) async throws -> String {
        var state = loadState()

        state.templates[name] = State.Template(
            command: command,
            description: description,
            project: project,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        try saveState(state)
        return "Template '\(name)' saved\n  Command: \(command)\(project != nil ? "\n  Project: \(project!)" : "")"
    }

    private static func templateList() async throws -> String {
        let state = loadState()

        if state.templates.isEmpty {
            return "No templates saved. Use dgx_template_save to create one."
        }

        var out = "=== Saved Templates ===\n\n"
        for (name, template) in state.templates.sorted(by: { $0.key < $1.key }) {
            out += "📋 \(name)\n"
            out += "   Command: \(template.command.prefix(60))\(template.command.count > 60 ? "..." : "")\n"
            if let desc = template.description {
                out += "   Description: \(desc)\n"
            }
            if let proj = template.project {
                out += "   Project: \(proj)\n"
            }
            out += "\n"
        }
        return out
    }

    private static func templateDelete(name: String) async throws -> String {
        var state = loadState()

        guard state.templates[name] != nil else {
            return "Template '\(name)' not found"
        }

        state.templates.removeValue(forKey: name)
        try saveState(state)
        return "Template '\(name)' deleted"
    }

    private static func templateRun(name: String, sync: Bool, container: String?) async throws -> String {
        let state = loadState()

        guard let template = state.templates[name] else {
            let available = state.templates.keys.joined(separator: ", ")
            return "Template '\(name)' not found. Available: \(available.isEmpty ? "(none)" : available)"
        }

        var out = "=== Running Template: \(name) ===\n"
        out += "Command: \(template.command)\n\n"

        // Sync project before if requested
        if sync, let project = template.project {
            out += "1. Syncing project '\(project)'...\n"
            let syncResult = try await DGX.sync(direction: "push", project: project)
            out += syncResult + "\n\n"
        }

        // Start the job
        out += sync ? "2. Starting job...\n" : "Starting job...\n"
        let jobResult = try await jobStart(command: template.command, name: nil, container: container, workdir: "/workspace")
        out += jobResult

        // Note about result sync
        if sync, let project = template.project {
            out += "\n\nResults will need manual sync after completion:\n"
            out += "  dgx_sync(direction: \"pull\", project: \"\(project)\")"
        }

        return out
    }

    // MARK: - Job Queue

    private static let queueFile = "/workspace/.jobs/queue.txt"

    private static func queueAdd(command: String?, template: String?, container: String?, workdir: String?) async throws -> String {
        let containerName = container ?? "twinprime"
        let dir = workdir ?? "/workspace"

        // Resolve command from template if needed
        var cmd: String
        if let templateName = template {
            let state = loadState()
            guard let t = state.templates[templateName] else {
                return "Template '\(templateName)' not found"
            }
            cmd = t.command
        } else if let c = command {
            cmd = c
        } else {
            return "Either 'command' or 'template' is required"
        }

        // Ensure jobs directory exists
        let _ = try await ssh("docker exec \(containerName) mkdir -p \(jobsDir)")

        // Add to queue file (one command per line, with workdir prefix)
        let entry = "\(dir)|\(cmd)"
        let escaped = entry.replacingOccurrences(of: "'", with: "'\"'\"'")
        let _ = try await ssh("docker exec \(containerName) bash -c 'echo '\"'\(escaped)'\"' >> \(queueFile)'")

        // Count queue size
        let (countStr, _) = try await ssh("docker exec \(containerName) wc -l < \(queueFile) 2>/dev/null || echo 0")
        let count = Int(countStr.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        return "Added to queue (position \(count)):\n  \(cmd)\n\nUse dgx_queue_start to begin processing"
    }

    private static func queueList(container: String?) async throws -> String {
        let containerName = container ?? "twinprime"

        // Check for running job
        let (running, _) = try await ssh("docker exec \(containerName) cat \(jobsDir)/queue_current.txt 2>/dev/null")
        let currentJob = running.trimmingCharacters(in: .whitespacesAndNewlines)

        // Get queue contents
        let (queue, ok) = try await ssh("docker exec \(containerName) cat \(queueFile) 2>/dev/null")

        var out = "=== Job Queue ===\n\n"

        if !currentJob.isEmpty {
            out += "▶️ Currently running: \(currentJob)\n\n"
        }

        if ok != 0 || queue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            out += "Queue: (empty)\n"
        } else {
            let entries = queue.split(separator: "\n")
            out += "Pending (\(entries.count)):\n"
            for (i, entry) in entries.enumerated() {
                let parts = entry.split(separator: "|", maxSplits: 1)
                let cmd = parts.count > 1 ? String(parts[1]) : String(entry)
                out += "  \(i + 1). \(cmd.prefix(60))\(cmd.count > 60 ? "..." : "")\n"
            }
        }

        return out
    }

    private static func queueClear(container: String?) async throws -> String {
        let containerName = container ?? "twinprime"

        let _ = try await ssh("docker exec \(containerName) rm -f \(queueFile)")
        return "Queue cleared"
    }

    private static func queueStart(container: String?) async throws -> String {
        let containerName = container ?? "twinprime"

        // Check if queue processor is already running
        let (_, procCheck) = try await ssh("docker exec \(containerName) pgrep -f 'queue_processor' >/dev/null 2>&1")
        if procCheck == 0 {
            return "Queue processor is already running"
        }

        // Create queue processor script
        let processorScript = """
            while [ -f \(queueFile) ] && [ -s \(queueFile) ]; do
                entry=$(head -n 1 \(queueFile))
                if [ -n "$entry" ]; then
                    workdir=$(echo "$entry" | cut -d'|' -f1)
                    cmd=$(echo "$entry" | cut -d'|' -f2-)
                    echo "$cmd" > \(jobsDir)/queue_current.txt
                    job_id="job_$(date +%s)"
                    cd "$workdir"
                    echo "$cmd" > \(jobsDir)/$job_id.cmd
                    echo 'running' > \(jobsDir)/$job_id.status
                    date +%s > \(jobsDir)/$job_id.start
                    (PYTHONUNBUFFERED=1 eval "$cmd") > \(jobsDir)/$job_id.log 2>&1
                    echo $? > \(jobsDir)/$job_id.exit
                    date +%s > \(jobsDir)/$job_id.end
                    echo 'completed' > \(jobsDir)/$job_id.status
                    sed -i '1d' \(queueFile)
                fi
            done
            rm -f \(jobsDir)/queue_current.txt
            """

        // Save and run processor
        let escaped = processorScript.replacingOccurrences(of: "'", with: "'\"'\"'").replacingOccurrences(of: "\n", with: "\\n")
        let _ = try await ssh("docker exec \(containerName) bash -c 'echo -e '\"'\(escaped)'\"' > \(jobsDir)/queue_processor.sh'")
        let _ = try await ssh("docker exec -d \(containerName) bash \(jobsDir)/queue_processor.sh")

        return "Queue processor started. Jobs will run sequentially.\n\nMonitor with:\n  dgx_queue_list - see progress\n  dgx_jobs - see completed jobs"
    }
}
