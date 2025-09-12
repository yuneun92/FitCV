from __future__ import annotations

import os
from typing import Optional

import redis
from dotenv import load_dotenv

load_dotenv()


def get_redis_client(url: Optional[str] = None) -> redis.Redis:
    redis_url = url or os.getenv("REDIS_URL", "redis://localhost:6379/0")
    return redis.from_url(redis_url, decode_responses=True) 