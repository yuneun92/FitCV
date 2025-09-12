## Job Posting 스키마 (초안)

```json
{
  "job_id": "string",
  "source": "worknet|saramin|greenhouse|lever|company",
  "company": {"name": "string", "size": "50-100", "industry": "string"},
  "title": "string",
  "locations": ["Seoul, KR"],
  "employment_type": "full-time|contract|intern",
  "salary": {"min": null, "max": null, "currency": "KRW"},
  "posted_at": "2025-09-13T00:00:00Z",
  "apply_url": "string",
  "jd": {
    "summary": "string",
    "requirements": ["..."],
    "preferred": ["..."],
    "responsibilities": ["..."],
    "keywords": ["Python","GraphDB","NLP"]
  },
  "employer_values": ["Customer-obsession","Ownership","속도"],
  "need_visa": false,
  "lang": "ko|en",
  "raw": {}
}
```

- `raw`: 원본 페이로드를 보관하여 추적성과 디버깅 용이성 확보 