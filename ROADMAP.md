# DGX MCP Roadmap

## Completed Features

### v1.0 - Core Tools
- [x] `dgx_status` - Host/GPU/container status
- [x] `dgx_gpu` - GPU utilization
- [x] `dgx_exec` - Run commands in container
- [x] `dgx_sync` - Push/pull project files
- [x] `dgx_telemetry` - Real-time stats from DGXDash

### v1.1 - Async Jobs
- [x] `dgx_job_start` - Non-blocking job execution
- [x] `dgx_jobs` - List jobs with status
- [x] `dgx_job_log` - View job output
- [x] `dgx_job_kill` - Kill running job

### v1.2 - Job Management (2025-01-05)
- [x] Job elapsed/duration time display
- [x] `dgx_job_watch` - Live updates with GPU stats + output diff
- [x] `dgx_job_retry` - Re-run completed jobs
- [x] `dgx_job_clean` - Remove old job files
- [x] `PYTHONUNBUFFERED=1` for real-time Python output
- [x] Reliable status detection via `.exit` file

### v1.3 - Templates & Queue (2025-01-05)
- [x] `dgx_template_save` - Save command templates
- [x] `dgx_template_list` - List templates
- [x] `dgx_template_run` - Run template with optional sync
- [x] `dgx_template_delete` - Delete template
- [x] `dgx_queue_add` - Add to job queue
- [x] `dgx_queue_list` - Show queue status
- [x] `dgx_queue_start` - Process queue sequentially
- [x] `dgx_queue_clear` - Clear pending queue

---

### v1.4 - Smart Monitoring (2025-01-05)
- [x] Error detection in logs (CUDA OOM, Traceback, exceptions)
- [x] Output metrics extraction (parse known patterns)
- [x] Pre-flight GPU check before starting jobs
- [x] Auto-suggest result sync on job completion

### v1.5 - Quality of Life (2025-01-05)
- [x] Last project memory (remember most recent project)
- [x] Run comparison (diff metrics between two jobs)
- [x] Job history stats (average runtime, success rate)

### v1.6 - Performance (2025-01-05)
- [x] SSH connection pooling/reuse (ControlMaster with 5min persist)
- [x] Batch SSH commands where possible (jobsList, jobStats)
- Performance: dgx_jobs 0.7s, dgx_job_stats 0.2s (down from 5-28s)

---

## Planned

(All features implemented!)

---

## Implementation Notes

### Error Detection Patterns
```
CUDA out of memory
RuntimeError:
Traceback (most recent call last)
MemoryError
KeyboardInterrupt
Killed
OOM
```

### Metrics Extraction Patterns (twin-prime specific)
```
Selection bias: (\d+\.\d+)%
Total runtime: (\d+\.\d+)s
Phase (\d): .* (\d+\.\d+)s
K = ([\d,]+)
GPU: (\d+)% util
```

### Pre-flight Checks
1. GPU utilization < 50%
2. Memory available > estimated need
3. No other jobs running (optional)
