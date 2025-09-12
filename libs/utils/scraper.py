from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator

import httpx


@contextmanager
def http_client(timeout_s: float = 10.0) -> Iterator[httpx.Client]:
    with httpx.Client(timeout=timeout_s, headers={"User-Agent": "FitCV/0.1"}) as client:
        yield client
