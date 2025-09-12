# (init) 0913 윤은 
# 개발 목적: Lever 공개 포스팅 수집기 개발
from __future__ import annotations

from typing import Any, Dict, List

import httpx

from .base import BaseCollector


class LeverCollector(BaseCollector):
    def __init__(self, company_slug: str, timeout_s: float = 10.0) -> None:
        self.company_slug = company_slug
        self.timeout_s = timeout_s

    def collect(self, **params: Any) -> List[Dict[str, Any]]:
        url = f"https://api.lever.co/v0/postings/{self.company_slug}?mode=json"
        with httpx.Client(
            timeout=self.timeout_s, headers={"User-Agent": "FitCV/0.1"}
        ) as client:
            resp = client.get(url)
            resp.raise_for_status()
            try:
                data = resp.json()
            except Exception:
                data = []
            return [{"source": "lever", "company": self.company_slug, "raw": data}]
