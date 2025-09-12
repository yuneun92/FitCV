from __future__ import annotations

import json
import os
from typing import Optional, List, Dict, Any

import redis
from dotenv import load_dotenv

load_dotenv()


def get_redis_client(url: Optional[str] = None) -> redis.Redis:
    redis_url = url or os.getenv("REDIS_URL", "redis://localhost:6379/0")
    return redis.from_url(redis_url, decode_responses=True)


def try_acquire_idempotency(key: str, ttl_seconds: int) -> bool:
    """Acquire an idempotency key with TTL. Returns True if acquired, False if exists."""
    client = get_redis_client()
    # SET key value NX EX ttl
    return bool(client.set(name=key, value="1", nx=True, ex=ttl_seconds))


def add_recent_task(task_info: Dict[str, Any], *, max_len: int | None = None) -> None:
    """Push a JSON task entry into a capped Redis list."""
    client = get_redis_client()
    list_key = os.getenv("RECENT_TASKS_LIST_KEY", "tasks:recent")
    max_size = max_len or int(os.getenv("RECENT_TASKS_MAX", "100"))
    client.lpush(list_key, json.dumps(task_info, ensure_ascii=False))
    client.ltrim(list_key, 0, max_size - 1)


def get_recent_tasks(limit: int = 50) -> List[Dict[str, Any]]:
    client = get_redis_client()
    list_key = os.getenv("RECENT_TASKS_LIST_KEY", "tasks:recent")
    raw_items = client.lrange(list_key, 0, max(0, limit - 1))
    results: List[Dict[str, Any]] = []
    for raw in raw_items:
        try:
            results.append(json.loads(raw))
        except Exception:
            continue
    return results 