## 데이터 소스 전략

| 소스 | 방식 | 비고 |
|---|---|---|
| WorkNet | 오픈API | 채용/공채속보, XML/JSON |
| Saramin | 오픈API | 검색/코드표 제공 |
| Greenhouse | Job Board API | 회사별 공개 잡보드 JSON |
| Lever | Postings/Data API/XML | 공개 포스팅/데이터 연동 |
| LinkedIn | 제한적 | 파트너 권한 필요(크롤링 비권장) |
| 기타 | 크롤링 | 회사 채용 페이지/뉴스룸, robots/약관 준수 |

- 정책: 각 소스 이용약관/robots 준수, API 키 보호, 요청률 제한
- 개인정보: 로컬 암호화/삭제 기능 제공 