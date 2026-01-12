# DGX MCP

MCP server for managing NVIDIA DGX Spark GPU workloads from Claude Code.

## Features

- **Container Management**: Start, stop, and monitor Docker containers
- **GPU Monitoring**: Real-time GPU utilization, memory, and temperature
- **Project Sync**: Push/pull files between local machine and DGX
- **Background Jobs**: Non-blocking job execution with progress tracking
- **Embedding Server**: Control the llama-embed-nemotron-8b server
- **Telemetry**: Integration with DGXDash iOS app for live stats

## Installation

Build and install the MCP server:

```bash
cd ~/.dgx/dgx-mcp
swift build -c release
cp .build/release/dgx-mcp ~/.dgx/
```

Add to Claude Code's MCP config (`~/.claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "dgx": {
      "command": "/Users/you/.dgx/dgx-mcp"
    }
  }
}
```

## Configuration

Create `~/.dgx/config.json`:

```json
{
  "hosts": {
    "spark": {
      "hostname": "your-dgx-hostname.local",
      "fallback_ip": "192.168.1.xxx",
      "user": "your-username"
    }
  },
  "containers": {
    "default": "your-container",
    "embedding-server": {
      "name": "embedding-server",
      "port": 8080
    }
  },
  "projects": {
    "your-project": {
      "local": "/path/to/local/project",
      "remote": "/workspace/project"
    }
  }
}
```

## Tools

### Status & Monitoring
| Tool | Description |
|------|-------------|
| `dgx_status` | Host connectivity, GPU info, container states |
| `dgx_gpu` | GPU utilization, memory, temperature |
| `dgx_disk` | Disk space on DGX |
| `dgx_containers` | List all Docker containers |
| `dgx_telemetry` | Real-time stats from DGXDash app |

### Container Management
| Tool | Description |
|------|-------------|
| `dgx_start` | Start a stopped container |
| `dgx_stop` | Stop a running container |
| `dgx_logs` | View container logs |
| `dgx_exec` | Run command in container |
| `dgx_check_updates` | Check for NGC image updates |
| `dgx_upgrade` | Upgrade to latest NGC image |

### Project Sync
| Tool | Description |
|------|-------------|
| `dgx_sync` | Push/pull project files |
| `dgx_run` | Sync, run command, sync results back |

### Background Jobs
| Tool | Description |
|------|-------------|
| `dgx_job_start` | Start background job (non-blocking) |
| `dgx_jobs` | List jobs with status |
| `dgx_job_log` | View job output |
| `dgx_job_watch` | Live updates with GPU stats |
| `dgx_job_kill` | Kill running job |
| `dgx_job_retry` | Re-run completed job |
| `dgx_job_clean` | Remove old job files |
| `dgx_job_compare` | Compare metrics between jobs |
| `dgx_job_stats` | Job history statistics |

### Templates & Queue
| Tool | Description |
|------|-------------|
| `dgx_template_save` | Save command as template |
| `dgx_template_list` | List saved templates |
| `dgx_template_run` | Run template |
| `dgx_template_delete` | Delete template |
| `dgx_queue_add` | Add job to queue |
| `dgx_queue_list` | Show queue status |
| `dgx_queue_start` | Process queue sequentially |
| `dgx_queue_clear` | Clear pending queue |

### Embedding Server
| Tool | Description |
|------|-------------|
| `dgx_embed_status` | Check server status |
| `dgx_embed_start` | Start embedding server (~90s) |
| `dgx_embed_stop` | Stop embedding server |

## Requirements

- macOS 13+
- Swift 5.9+
- SSH access to DGX Spark
- Docker on DGX with NGC containers

## License

MIT
