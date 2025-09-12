from __future__ import annotations

from typing import Any, Dict, List

import httpx

from .base import BaseCollector


class WorkNetCollector(BaseCollector):
    def __init__(self, service_key: str, timeout_s: float = 10.0) -> None:
        self.service_key = service_key
        self.timeout_s = timeout_s

    def collect(self, **params: Any) -> List[Dict[str, Any]]:
        # 실제 엔드포인트/파라미터는 WorkNet 오픈API 명세에 따름.
        base = "https://openapi.work.go.kr/opi/opi/opia/wantedApi.do"
        query = {
            "ServiceKey": self.service_key,
            "callTp": "L",
            "returnType": "JSON",
        }
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
            return [{"source": "worknet", "raw": data}]
