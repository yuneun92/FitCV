from __future__ import annotations

import os
from typing import List

from celery import Celery
from dotenv import load_dotenv

# Load environment variables from a local .env if present
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "..", ".env"))
load_dotenv()  # Fallback to project root or cwd


def _parse_slugs(env_value: str | None) -> List[str]:
    if not env_value:
        return []
    return [s.strip() for s in env_value.split(",") if s.strip()]


REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
BROKER_URL = os.getenv("CELERY_BROKER_URL", REDIS_URL)
RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND", REDIS_URL)

app = Celery(
    "fitcv",
    broker=BROKER_URL,
    backend=RESULT_BACKEND,
    include=["FitCV.apps.worker.tasks"],
)

# Base configuration
app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone=os.getenv("CELERY_TIMEZONE", "UTC"),
    enable_utc=True,
)

# Queues and routing
app.conf.task_default_queue = os.getenv("CELERY_DEFAULT_QUEUE", "default")
app.conf.task_queues = {
    "default": {
        "exchange": "default",
        "routing_key": "default",
    },
    "greenhouse": {
        "exchange": "greenhouse",
        "routing_key": "greenhouse",
    },
}
app.conf.task_routes = {
    "FitCV.apps.worker.tasks.scrape_greenhouse_task": {"queue": "greenhouse"},
    "FitCV.apps.worker.tasks.scrape_greenhouse_single_task": {"queue": "greenhouse"},
    "FitCV.apps.worker.tasks.dispatch_greenhouse_scrape": {"queue": "greenhouse"},
}

# Optional: Celery Beat schedule configured from env (using dispatch for fan-out)
SCRAPE_INTERVAL_SECONDS = float(os.getenv("SCRAPE_INTERVAL_SECONDS", "0"))
GREENHOUSE_SLUGS = _parse_slugs(os.getenv("GREENHOUSE_SLUGS"))
DATA_DIR = os.getenv(
    "DATA_DIR",
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "data")),
)
DEFAULT_TIMEOUT_SECONDS = float(os.getenv("SCRAPE_TIMEOUT_SECONDS", "15"))
ENABLE_CELERY_BEAT = os.getenv("ENABLE_CELERY_BEAT", "true").lower() in {"1", "true", "yes"}

if ENABLE_CELERY_BEAT and SCRAPE_INTERVAL_SECONDS > 0 and GREENHOUSE_SLUGS:
    app.conf.beat_schedule = {
        "scrape-greenhouse-periodic": {
            "task": "FitCV.apps.worker.tasks.dispatch_greenhouse_scrape",
            "schedule": SCRAPE_INTERVAL_SECONDS,
            "args": [GREENHOUSE_SLUGS, DATA_DIR, DEFAULT_TIMEOUT_SECONDS],
        }
    }


__all__ = ["app"] 