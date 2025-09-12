## CI 통과 가이드

### 요구사항
- Python 3.12
- uv 사용 환경

### 로컬 확인 절차
1. 의존성 설치
   - `uv pip install -U ruff black pytest`
   - 또는 Python 3.12에서 `uv pip install -e '.[dev]'`
2. 포맷/린트/테스트
   - `uv run black --check --diff .`
   - `uv run ruff check .`
   - `uv run pytest -q tests`
3. 자동 훅(권장)
   - `uv run pre-commit install`
   - `uv run pre-commit install -t pre-push`
   - 커밋 시 black/ruff, 푸시 시 전체 테스트 수행

### CI 구성(요약)
- 파일: `.github/workflows/ci.yml`
- 단계: ruff → black --check → pytest
- 실패 원인 예시
  - Black 포맷 불일치: `uv run black .`로 자동 정정 후 커밋
  - ruff 규칙 위반: `uv run ruff --fix .`로 자동 수정 가능
  - 테스트 실패: `tests` 하위 테스트를 수정/보완

### 트러블슈팅
- Python 버전 오류: 3.12 가상환경에서 uv 명령 실행
- 경로 문제: pytest는 `tests` 기준. 다른 경로의 테스트는 `pyproject.toml`의 `testpaths` 수정 

# CI/CD 가이드

- 테스트 실행: `uv run pytest`
- Lint: `uv run ruff check . && uv run black --check .`
- 백그라운드 작업: Celery/Redis는 통합 테스트에서 모킹하거나 로컬 서비스로 기동합니다. 