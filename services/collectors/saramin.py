# (init) 0913 윤은 
# 개발 목적: 사람인 공고 스크랩 API 개발

from __future__ import annotations

from typing import Any, Dict, List

import httpx

from .base import BaseCollector


class SaraminCollector(BaseCollector):
    def __init__(self, access_key: str, timeout_s: float = 10.0) -> None:
        self.access_key = access_key
        self.timeout_s = timeout_s

    def collect(self, **params: Any) -> List[Dict[str, Any]]:
        # 실제 엔드포인트는 oapi.saramin.co.kr 명세에 따름. 최소 호출 형태 예시.
        base = "https://oapi.saramin.co.kr/job-search"
        query = {"access-key": self.access_key, "format": "json"}
        query.update({k: v for k, v in params.items() if v is not None})
        with httpx.Client(
            timeout=self.timeout_s, headers={"User-Agent": "FitCV/0.1"}
        ) as client:
            resp = client.get(base, params=query)
            resp.raise_for_status()
            try:
                data = resp.json()
            except Exception:
                data = resp.text
            return [{"source": "saramin", "raw": data}]
