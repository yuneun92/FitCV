## 생성 로직

### 매칭 단계
- 룰: JD requirements ⊂ 사용자 skills/experience
- 가중치: JD/기업가치 키워드 가중치↑, 최신성 가중치
- 점수: `fit_score = must_hit + pref_hit + value_alignment + recency_weight`

### 템플릿(샘플)
```
[Company Values]: {{ values | join(', ') }}
[JD Must/Pref]: {{ must_keywords }} / {{ pref_keywords }}

문항: "{{ question }}"
지시:
1) 사용자 프로필에서 관련 경험 1~2개만 선택.
2) STAR 구조로 500~700자.
3) JD Must 키워드는 최소 3개 이상 자연스럽게 포함.
4) 수치(%, ↑, ↓, 기간)를 꼭 넣기.
5) 회사 톤(예: {{ tone_desc }})을 반영.
출력:
- 본문
- 사용한 근거경험 ID 목록
- 포함된 키워드 리스트
``` 