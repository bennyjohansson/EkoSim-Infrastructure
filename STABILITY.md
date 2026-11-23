# Stability verification

The backend defaults to 512 MiB memory, no additional swap allowance, and 0.75 CPU. Override SIMULATOR_MEMORY_LIMIT and SIMULATOR_CPU_LIMIT to suit the host. All four services rotate Docker json-file logs at 10 MiB with three files retained. Production Nginx uses the official image stdout/stderr log links instead of a host log-directory mount, so these logs also pass through Docker rotation. Recreate existing containers to apply these settings. Inspect HostConfig on the running containers to verify the effective values.

Development PostgreSQL publishes on loopback port 5545 by default. POSTGRES_PUBLISHED_PORT changes the host port. The simulator has no published port. Production API health checks use /ready. API liveness remains /health. /health/simulation reports whether each city's latest saved time-data row is recent. SIMULATION_MAX_AGE_SECONDS defaults to 120 and should exceed the expected cycle duration. Cycle counter resets are supported through database timestamps. Empty data reports starting, old data reports stale, and database errors report unavailable, all with HTTP 503.

## Soak test

After building and starting the stack, sample it for 12 hours from this directory.

```sh
python3 scripts/stability-soak.py --hours 12 --output logs/stability-soak.jsonl
```

For an override, append --compose-file docker-compose.yml --compose-file /tmp/ekosim-local.override.yml. For production, use --compose-file docker-compose.prod-postgresql.yml and supply the deployed API and frontend URLs with --api and --frontend.

Keep the computer awake and Docker running for the full duration. The sampler records timestamps, backend restart/OOM state, CPU and memory statistics, memory/CPU limits and logging settings, writable-layer size, container filesystem usage, database size, per-city cycle/timestamps, high-score inserts, and frontend/API/readiness/progress responses. Log-file size is recorded only when the Docker daemon's log path is accessible to the host, which is usually unavailable on Docker Desktop. The output is created exclusively to prevent overwriting earlier results. The sampler never deletes data or containers.

Review the complete trace for repeated finished worlds, memory settling after warm-up, zero unexpected restarts/OOM kills, bounded storage growth and uninterrupted readiness. High-score insert counts are progress evidence across resets, and count city results. Review memory at comparable points in successive runs. A successful sampler exit records completed sampling and does not itself certify stability. Monitor the shared host's other applications during a staging fault-isolation test.

## Incident evidence

On the VM, collect container inspect state, docker stats, docker system df, filesystem free space, and kernel journal OOM entries around the incident timestamp. Preserve logs before restarting services. The historical VM outage cause remains unverified.
