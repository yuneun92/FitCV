from __future__ import annotations

from typing import Iterable, List, Tuple

from FitCV.services.jobs import scrape_greenhouse_once
from .celery_app import app


@app.task(
    name="FitCV.apps.worker.tasks.scrape_greenhouse_task",
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_backoff_max=300,
    retry_jitter=True,
    max_retries=5,
)
def scrape_greenhouse_task(
    self,
    company_slugs: Iterable[str],
    output_root: str,
    timeout_seconds: float = 15.0,
) -> List[Tuple[str, int, str]]:
    """Scrape greenhouse for given slugs and persist to JSONL files.

    Returns list of tuples (slug, num_items, output_file_path).
    """
    return scrape_greenhouse_once(company_slugs, output_root, timeout_seconds=timeout_seconds) 