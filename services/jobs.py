from __future__ import annotations

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Iterable, List, Tuple

from FitCV.services.collectors.greenhouse import GreenhouseCollector


def _ensure_dir(path: str | Path) -> None:
    Path(path).mkdir(parents=True, exist_ok=True)


def scrape_greenhouse_once(
    company_slugs: Iterable[str],
    output_root: str | Path,
    *,
    timeout_seconds: float = 15.0,
) -> List[Tuple[str, int, str]]:
    """Scrape Greenhouse postings for the provided slugs and write to JSONL files.

    Returns a list of tuples: (slug, num_items, output_file_path).
    """
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    results: List[Tuple[str, int, str]] = []
    for slug in company_slugs:
        collector = GreenhouseCollector(company_slug=slug, timeout_s=timeout_seconds)
        items = collector.collect()
        # Each slug gets its own directory and timestamped JSONL file
        out_dir = Path(output_root) / "greenhouse" / slug
        _ensure_dir(out_dir)
        out_file = out_dir / f"{timestamp}.jsonl"
        with out_file.open("w", encoding="utf-8") as f:
            for item in items:
                f.write(json.dumps(item, ensure_ascii=False) + "\n")
        results.append((slug, len(items), str(out_file)))
    return results 