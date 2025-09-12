from fastapi import FastAPI
import os
from typing import List

from FitCV.apps.worker.tasks import scrape_greenhouse_task

app = FastAPI()


@app.get("/healthz")
def read_health() -> dict[str, str]:
    return {"status": "ok"}


def _parse_slugs(env_value: str | None) -> List[str]:
    if not env_value:
        return []
    return [s.strip() for s in env_value.split(",") if s.strip()]


@app.get("/config/scrape")
def get_scrape_config() -> dict[str, object]:
    return {
        "greenhouse_slugs": _parse_slugs(os.getenv("GREENHOUSE_SLUGS")) or ["gitlab"],
        "interval_seconds": float(os.getenv("SCRAPE_INTERVAL_SECONDS", "3600")),
        "timeout_seconds": float(os.getenv("SCRAPE_TIMEOUT_SECONDS", "15")),
        "data_dir": os.getenv(
            "DATA_DIR",
            os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "data")),
        ),
    }


@app.on_event("startup")
def _configure_defaults() -> None:
    # No thread-based scheduler; Celery Beat handles periodic runs if enabled.
    pass


@app.post("/tasks/scrape/greenhouse/trigger")
def trigger_scrape_greenhouse() -> dict[str, str]:
    greenhouse_slugs = _parse_slugs(os.getenv("GREENHOUSE_SLUGS")) or ["gitlab"]
    data_dir = os.getenv(
        "DATA_DIR",
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "data")),
    )
    timeout_seconds = float(os.getenv("SCRAPE_TIMEOUT_SECONDS", "15"))

    scrape_greenhouse_task.delay(greenhouse_slugs, data_dir, timeout_seconds)
    return {"enqueued": "scrape_greenhouse_task"}
