#!/usr/bin/env python3
"""Generate Angel Arena UI art with Azure gpt-image-2.5 (Flare / Sunburst).

Reads the API key from the environment (never stored), writes the raw PNGs to --out and
appends prompt / model / settings / request id for every image to generation_log.json.

    python tools/ui_art/generate_ui_art.py --out <dir> [--jobs <file>] [--workers N] [name ...]

--jobs defaults to prompts.json next to this script. Images that already exist in --out are
kept, so an interrupted run can be resumed.
"""
import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ENDPOINT = "https://baladia-test-ai-resource.services.ai.azure.com/openai/v1/images/generations"
KEY_VARS = ("AZURE_AI_FOUNDRY_API_KEY", "AZURE_OPENAI_API_KEY", "AZURE_API_KEY")
HERE = Path(__file__).resolve().parent
STYLE = (
    "Dark fantasy digital matte painting, painterly brushwork, rich but restrained colour, "
    "ancient weathered stone, warm firelight against cold blue dusk shadows, cinematic lighting. "
    "No text, no letters, no watermark, no UI, no people, no characters."
)


def request(job, key):
    body = {
        "model": job["model"],
        "prompt": job["prompt"].replace("{STYLE}", STYLE),
        "size": job["size"],
        "quality": job.get("quality", "high"),
        "n": 1,
        "output_format": "png",
        "background": job.get("background", "opaque"),
    }
    req = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(body).encode(),
        method="POST",
        headers={"api-key": key, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=600) as resp:
        payload = json.loads(resp.read())
        rid = resp.headers.get("apim-request-id") or resp.headers.get("x-request-id")
    return body, payload, rid


def run(job, out):
    last = None
    for var in KEY_VARS:
        key = os.environ.get(var)
        if not key:
            continue
        for attempt in range(3):
            try:
                started = time.time()
                body, payload, rid = request(job, key)
                png = base64.b64decode(payload["data"][0]["b64_json"])
                target = out / (job["name"] + ".png")
                target.write_bytes(png)
                return {
                    "name": job["name"],
                    "file": target.name,
                    "request": body,
                    "request_id": rid,
                    "key_variable": var,
                    "seconds": round(time.time() - started, 1),
                    "usage": payload.get("usage"),
                }
            except urllib.error.HTTPError as err:
                detail = err.read().decode("utf-8", "replace")[:600]
                last = f"{var}: HTTP {err.code} {detail}"
                if err.code in (401, 403, 404):
                    break  # wrong key for this resource: try the next variable
                if err.code == 400:
                    return {"name": job["name"], "error": last}
                time.sleep(8 * (attempt + 1))
            except Exception as err:  # network hiccup: retry
                last = f"{var}: {type(err).__name__} {err}"
                time.sleep(5)
    return {"name": job["name"], "error": last or "no API key variable set"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--jobs", default=str(HERE / "prompts.json"))
    parser.add_argument("--workers", type=int, default=3)
    parser.add_argument("names", nargs="*")
    args = parser.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    jobs = json.loads(Path(args.jobs).read_text(encoding="utf-8"))
    jobs = [job for job in jobs if not args.names or job["name"] in args.names]
    jobs = [job for job in jobs if not (out / (job["name"] + ".png")).exists()]
    log_path = HERE / "generation_log.json"
    log = json.loads(log_path.read_text(encoding="utf-8")) if log_path.exists() else []
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        for result in pool.map(lambda job: run(job, out), jobs):
            result["time"] = time.strftime("%Y-%m-%dT%H:%M:%S")
            log.append(result)
            log_path.write_text(json.dumps(log, indent=2), encoding="utf-8")
            status = "ERROR " + result["error"] if "error" in result else f"ok {result['seconds']}s"
            print(result["name"], status, flush=True)


if __name__ == "__main__":
    sys.exit(main())
