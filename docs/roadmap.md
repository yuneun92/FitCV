## 4주 MVP 로드맵

- W1: 수집(WorkNet/Saramin/Greenhouse/Lever) + 정규화 스키마 + 기본 매칭(룰)
- W2: 인재상 추출(사전+TF-IDF), 템플릿, 2~3개 문항 자동생성
- W3: 리뷰/평점, 내보내기(PDF/Docx), 대시보드 초안
- W4: 사용자 피드백 반영, 프롬프트 튜닝, 속도/캐시/로그/테스트

## 바로 시작할 이슈
- WorkNet Collector 구현(+키 발급/샘플 호출)
- Saramin Collector 구현(+코드표 매핑)
- Greenhouse/Lever Collector 구현(회사 도메인별 잡보드)
- Normalizer 작성(공통 스키마)
- Matcher v1(룰 기반) + 점수 산식
- 기업 인재상 키워드 추출기(v1, 사전+TF-IDF)
- 프롬프트 템플릿 5종(지원동기/역량/팀워크/문제해결/성장)
- 자소서/포폴 생성기 + 근거 링크
- Reviewer(금지어·톤·맞춤법)
- PDF/Docx Exporter
- Web 대시보드(추천 공고/생성·수정/내보내기) 