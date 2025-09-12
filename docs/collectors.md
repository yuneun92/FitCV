## 수집 어댑터 설계

### 공통 인터페이스
- `collect(params) -> List[RawJob]`

### 어댑터 목록
- WorknetCollector: 인증키, 카테고리/지역/키워드, XML→dict 파서
- SaraminCollector: access-key, 검색 API, 코드표 매핑
- GreenhouseCollector: `/boards/{company}/jobs` JSON
- LeverCollector: `/postings/{company}` 또는 Data API/XML
- CompanyPageCrawler: Playwright, robots/약관 체크, 레이트리밋/캐시

### 사용 예시(초안)
```python
from FitCV.services.collectors.greenhouse import GreenhouseCollector

collector = GreenhouseCollector(company_slug="exampleco")
raw_jobs = collector.collect()
```