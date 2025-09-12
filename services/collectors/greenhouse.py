# (init) 0913 윤은 
# 개발 목적: Greenhouse 공개 잡보드 수집기 개발
from __future__ import annotations

from typing import Any, Dict, List

import httpx

from .base import BaseCollector


class GreenhouseCollector(BaseCollector):
    def __init__(self, company_slug: str, timeout_s: float = 10.0) -> None:
        self.company_slug = company_slug
        self.timeout_s = timeout_s

    def collect(self, **params: Any) -> List[Dict[str, Any]]:
        api_url = f"https://boards-api.greenhouse.io/v1/boards/{self.company_slug}/jobs"
        query: Dict[str, Any] = {"content": True}
        query.update({k: v for k, v in params.items() if v is not None})
        with httpx.Client(timeout=self.timeout_s, headers={"User-Agent": "FitCV/0.1"}) as client:
            resp = client.get(api_url, params=query)
            resp.raise_for_status()
            data = resp.json()
            jobs = data.get("jobs", []) if isinstance(data, dict) else []
            return [
                {"source": "greenhouse", "company": self.company_slug, "raw": job}
                for job in jobs
            ]
