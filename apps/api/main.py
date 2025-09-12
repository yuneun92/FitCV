from fastapi import FastAPI
import os
from typing import List

from celery.result import AsyncResult
from FitCV.apps.worker.tasks import scrape_greenhouse_task, dispatch_greenhouse_scrape
from FitCV.apps.worker.celery_app import app as celery_app
from FitCV.libs.cache.redis import get_recent_tasks

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
def trigger_scrape_greenhouse(idem_ttl_seconds: int = 300) -> dict[str, str]:
    greenhouse_slugs = _parse_slugs(os.getenv("GREENHOUSE_SLUGS")) or ["gitlab"]
    data_dir = os.getenv(
        "DATA_DIR",
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "data")),
    )
    timeout_seconds = float(os.getenv("SCRAPE_TIMEOUT_SECONDS", "15"))

    # Use dispatcher for fan-out execution
    async_result = dispatch_greenhouse_scrape.delay(
        greenhouse_slugs, data_dir, timeout_seconds, idem_ttl_seconds=idem_ttl_seconds
    )
    return {"enqueued": "dispatch_greenhouse_scrape", "task_id": async_result.id}


@app.get("/tasks/{task_id}")
def get_task_status(task_id: str) -> dict[str, object]:
    result = AsyncResult(task_id, app=celery_app)
    payload: dict[str, object] = {
        "id": task_id,
        "state": result.state,
        "ready": result.ready(),
        "successful": result.successful() if result.ready() else False,
    }
    if result.failed():
        payload["error"] = str(result.result)
    if result.ready() and result.successful():
        # Group result may not have a concrete return; we expose it if present
        payload["result"] = result.result
    return payload


@app.get("/tasks/recent")
def get_recent(limit: int = 50) -> dict[str, object]:
    items = get_recent_tasks(limit=limit)
    return {"items": items}
