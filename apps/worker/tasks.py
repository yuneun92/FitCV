from __future__ import annotations

from typing import Iterable, List, Tuple

from celery import group

from FitCV.services.jobs import scrape_greenhouse_once
from FitCV.libs.cache.redis import try_acquire_idempotency, add_recent_task
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


@app.task(
    name="FitCV.apps.worker.tasks.scrape_greenhouse_single_task",
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_backoff_max=300,
    retry_jitter=True,
    max_retries=5,
)
def scrape_greenhouse_single_task(
    self,
    company_slug: str,
    output_root: str,
    timeout_seconds: float = 15.0,
) -> Tuple[str, int, str]:
    """Scrape one company slug and return a single tuple result."""
    results = scrape_greenhouse_once([company_slug], output_root, timeout_seconds=timeout_seconds)
    return results[0]


@app.task(
    name="FitCV.apps.worker.tasks.dispatch_greenhouse_scrape",
)
def dispatch_greenhouse_scrape(
    company_slugs: Iterable[str],
    output_root: str,
    timeout_seconds: float = 15.0,
    *,
    idem_ttl_seconds: int | None = 300,
) -> str:
    """Dispatch fan-out tasks per slug and return the group id.

    Uses Redis idempotency key to avoid duplicate dispatch in a short window.
    """
    slugs = list(company_slugs)
    if idem_ttl_seconds and idem_ttl_seconds > 0:
        idem_key = f"scrape:greenhouse:{','.join(sorted(slugs))}:{int(timeout_seconds)}"
        if not try_acquire_idempotency(idem_key, idem_ttl_seconds):
            add_recent_task({
                "type": "dispatch_greenhouse_scrape",
                "status": "skipped-idempotent",
                "slugs": slugs,
            })
            return "skipped"

    task_sigs = [
        scrape_greenhouse_single_task.s(slug, output_root, timeout_seconds) for slug in slugs
    ]
    grp = group(task_sigs)
    res = grp.apply_async()

    add_recent_task({
        "type": "dispatch_greenhouse_scrape",
        "status": "enqueued",
        "group_id": res.id,
        "slugs": slugs,
    })
    return res.id 