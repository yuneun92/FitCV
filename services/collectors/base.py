# (init) 0913 윤은 
# 개발 목적: 수집 어댑터 공통 인터페이스 정의
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Dict, List


class BaseCollector(ABC):
    """모든 수집 어댑터의 공통 인터페이스."""

    @abstractmethod
    def collect(self, **params: Any) -> List[Dict[str, Any]]:
        """원본 공고 리스트를 수집하여 반환한다.
        반환 데이터는 normalizer에서 공통 스키마로 매핑된다.
        """
        raise NotImplementedError
