#!/usr/bin/env python3
"""Sample an existing EkoSim Compose stack without changing its data or containers."""
import argparse
import datetime as dt
import json
from pathlib import Path
import subprocess
import time
import urllib.error
import urllib.request


def run(args, timeout=20):
    result = subprocess.run(args, text=True, capture_output=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Command failed")
    return result.stdout


def http_status(url):
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            return {"status": response.status, "body": response.read(16384).decode()}
    except urllib.error.HTTPError as error:
        return {"status": error.code, "body": error.read(16384).decode()}
    except (OSError, urllib.error.URLError) as error:
        return {"error": str(error)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hours", type=float, default=12)
    parser.add_argument("--interval", type=float, default=60)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--api", default="http://localhost:3001")
    parser.add_argument("--frontend", default="http://localhost:3000")
    parser.add_argument("--compose-file", action="append", default=[])
    args = parser.parse_args()
    if args.hours <= 0 or args.interval <= 0:
        parser.error("hours and interval must be positive")
    compose = ["docker", "compose"]
    for filename in args.compose_file or ["docker-compose.yml"]:
        compose += ["-f", filename]
    ids = {}
    for service in ["ekosim-backend", "ekosim-postgres", "ekosim-api", "ekosim-frontend"]:
        ids[service] = run(compose + ["ps", "-q", service]).strip()
        if not ids[service]:
            raise RuntimeError(service + " is unavailable")
    # Verify access before creating a report or beginning the timer.
    run(["docker", "inspect", ids["ekosim-backend"]])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    deadline = time.monotonic() + args.hours * 3600
    samples = 0
    failures = 0
    previous_scores = None
    completed_worlds = 0
    sql = """SELECT json_build_object(
      'database_bytes', pg_database_size(current_database()),
      'high_scores', (SELECT count(*) FROM high_scores),
      'cities', (SELECT json_agg(t) FROM
        (SELECT city_name, MAX(time) AS cycle, MAX(created_at) AS latest,
          EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(created_at))) AS age_seconds
         FROM time_data GROUP BY city_name) t))"""
    with args.output.open("x", buffering=1) as output:
        while True:
            sample = {"timestamp": dt.datetime.now(dt.timezone.utc).isoformat()}
            try:
                state = json.loads(run(["docker", "inspect", "--size", ids["ekosim-backend"]]))[0]
                sample["backend"] = {
                    "running": state["State"]["Running"],
                    "restarts": state["RestartCount"],
                    "oom_killed": state["State"]["OOMKilled"],
                    "started_at": state["State"]["StartedAt"],
                    "writable_bytes": state.get("SizeRw"),
                    "memory_limit": state["HostConfig"]["Memory"],
                    "nano_cpus": state["HostConfig"]["NanoCpus"],
                    "logging": state["HostConfig"]["LogConfig"]}
                sample["stats"] = [json.loads(line) for line in run(
                    ["docker", "stats", "--no-stream", "--format", "{{json .}}", *ids.values()]).splitlines()]
                log_path = Path(state.get("LogPath", "/nonexistent"))
                sample["log_file_bytes"] = log_path.stat().st_size if log_path.is_file() else None
                sample["disk"] = run(["docker", "exec", ids["ekosim-backend"], "df", "-Pk", "/app"])
                query = ["docker", "exec", ids["ekosim-postgres"], "sh", "-c",
                         'exec psql -XAt -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "$1"',
                         "soak-query", sql]
                sample["database"] = json.loads(run(query))
                scores = sample["database"]["high_scores"]
                if previous_scores is not None:
                    completed_worlds += max(0, scores - previous_scores)
                previous_scores = scores
                sample["high_score_inserts_observed"] = completed_worlds
                sample["api"] = http_status(args.api + "/health")
                sample["readiness"] = http_status(args.api + "/ready")
                sample["progress"] = http_status(args.api + "/health/simulation")
                sample["frontend"] = http_status(args.frontend)
            except (OSError, RuntimeError, ValueError, subprocess.TimeoutExpired) as error:
                sample["error"] = str(error)
                failures += 1
            output.write(json.dumps(sample) + "\n")
            samples += 1
            if time.monotonic() >= deadline:
                break
            time.sleep(min(args.interval, max(0, deadline - time.monotonic())))
        output.write(json.dumps({"finished": True, "samples": samples,
            "sample_errors": failures, "high_score_inserts_observed": completed_worlds}) + "\n")
    print("Completed sampling. Review memory trends, progress gaps, errors and restart counts in", args.output)


if __name__ == "__main__":
    main()
