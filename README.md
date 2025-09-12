# FitCV

내 프로필 태그와 채용 공고(JD/인재상)를 매칭해 **자소서/포트폴리오**를 자동 생성하는 서비스.

---

## ✨ Features

* **채용 공고 집계**: WorkNet, Saramin, Greenhouse, Lever, 기업 채용 페이지 수집/정규화
* **JD/인재상 분석**: 기업 핵심가치 및 Job Description 키워드 추출
* **적합도 매칭**: 사용자 태그/프로필 ↔ 공고 키워드 매칭 스코어
* **자소서/포폴 생성**: 템플릿 + LLM 프롬프트로 맞춤 문서 자동 작성
* **리뷰 & 교정**: 금지어 탐지, 맞춤법/톤 점검, 개인정보 필터링
* **내보내기**: PDF / DOCX / Markdown 지원

---

## 🚀 Quickstart

### 1. Clone & Install

```bash
git clone https://github.com/yourname/git
cd FitCV
```

### 2. 환경 변수 설정

`.env` 파일 생성 후 API 키/DB URL 입력

```bash
cp .env.example .env
```

### 3. 개발 서버 실행 (Docker Compose)

```bash
docker compose up -d
```

* API: [http://localhost:8000](http://localhost:8000)
* Web: [http://localhost:3000](http://localhost:3000)

---

## 🗂 Repo Structure

```

├─ apps/            # api, web, worker (서비스 앱)
├─ services/        # collectors, normalizer, matcher, generator...
├─ libs/            # schemas, prompts, nlp, utils
├─ data/            # seeds, cache
├─ infra/           # docker, k8s, scripts
├─ tests/           # unit, e2e, contract
├─ .github/         # 이슈 템플릿, 워크플로우
└─ README.md
```

---

## 📦 Tech Stack

* **Backend**: FastAPI, Pydantic, Celery, Redis
* **Frontend**: Next.js(App Router), Tailwind CSS
* **Database**: PostgreSQL, Meilisearch(검색)
* **Infra**: Docker, GitHub Actions CI/CD
* **LLM**: OpenAI / HuggingFace (선택)

---

## 📋 API Endpoints (MVP)

* `GET /jobs`: 채용 공고 검색
* `GET /jobs/{id}`: 공고 상세
* `PUT /profiles/{id}`: 사용자 프로필 저장
* `POST /generate/cover-letter`: 자소서 생성
* `POST /generate/portfolio`: 포트폴리오 생성
* `POST /review`: 리뷰/교정

---

## 🛠 Development

* 코드 스타일: [Black](https://github.com/psf/black), [isort](https://github.com/PyCQA/isort)
* 커밋 컨벤션: Conventional Commits
* 브랜치 전략: `main` (stable), `dev` (active), `feat/*`, `fix/*`

---

## 📌 Roadmap (MVP \~4주)

* [ ] WorkNet/Saramin/Greenhouse/Lever 수집기 구현
* [ ] JD/인재상 분석기
* [ ] 매칭 스코어러 v1
* [ ] 자소서/포폴 생성 템플릿
* [ ] Reviewer 모듈
* [ ] Next.js 대시보드
* [ ] Exporter(PDF/DOCX)

---

## 🔒 Security & Policy

* API/데이터 소스 약관 준수 (WorkNet, Saramin 등)
* 개인정보 최소 수집 및 암호화
* API Key/Secret은 `.env`와 GitHub Secrets에서 관리