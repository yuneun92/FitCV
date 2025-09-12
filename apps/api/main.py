from fastapi import FastAPI
import os
from typing import List

from FitCV.services.scheduler import PeriodicJobRunner
from FitCV.services.jobs import scrape_greenhouse_once

app = FastAPI()


@app.get("/healthz")
def read_health() -> dict[str, str]:
    return {"status": "ok"}


def _parse_slugs(env_value: str | None) -> List[str]:
    if not env_value:
        return []
    return [s.strip() for s in env_value.split(",") if s.strip()]


@app.on_event("startup")
def _start_scheduler() -> None:
    greenhouse_slugs = _parse_slugs(os.getenv("GREENHOUSE_SLUGS")) or ["gitlab"]
    interval_seconds = float(os.getenv("SCRAPE_INTERVAL_SECONDS", "3600"))
    data_dir = os.getenv("DATA_DIR", os.path.join(os.path.dirname(__file__), "..", "..", "data"))
    data_dir = os.path.abspath(data_dir)

    def _info(msg: str) -> None:
        print(msg)

    def _error(exc: BaseException) -> None:
        print(f"[scheduler] error: {exc}")

    def _job() -> None:
        results = scrape_greenhouse_once(greenhouse_slugs, data_dir)
        for slug, n, path in results:
            _info(f"[scrape] greenhouse slug={slug} items={n} -> {path}")

    runner = PeriodicJobRunner(
        name="scraper",
        interval_seconds=interval_seconds,
        job_function=_job,
        on_error=_error,
        on_info=_info,
    )
    app.state.scraper_runner = runner
    runner.start()


@app.on_event("shutdown")
def _stop_scheduler() -> None:
    runner = getattr(app.state, "scraper_runner", None)
    if runner is not None:
        runner.stop()
