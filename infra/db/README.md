# FitCV 데이터베이스 설치 가이드

이 문서는 FitCV 프로젝트의 PostgreSQL 데이터베이스 설치 및 설정 가이드입니다.

## 1. 사전 요구사항

### PostgreSQL 설치
```bash
# macOS (Homebrew)
brew install postgresql@15
brew services start postgresql@15

# Ubuntu/Debian
sudo apt update
sudo apt install postgresql-15 postgresql-contrib-15

# CentOS/RHEL
sudo dnf install postgresql15-server postgresql15-contrib
```

### 필요한 확장 기능
- `uuid-ossp`: UUID 생성용
- `pg_trgm`: 유사도 검색용 (trigram)

## 2. 데이터베이스 생성

### 데이터베이스 및 사용자 생성
```sql
-- PostgreSQL 관리자로 접속
sudo -u postgres psql

-- 데이터베이스 생성
CREATE DATABASE fitcv_db;

-- 사용자 생성 및 권한 부여
CREATE USER fitcv_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE fitcv_db TO fitcv_user;

-- 사용자에게 스키마 생성 권한 부여
ALTER USER fitcv_user CREATEDB;

-- 연결 종료
\q
```

### 환경 변수 설정
`.env` 파일에 데이터베이스 연결 정보 추가:
```env
# 데이터베이스 설정
DB_HOST=localhost
DB_PORT=5432
DB_NAME=fitcv_db
DB_USER=fitcv_user
DB_PASSWORD=your_secure_password
DB_URL=postgresql://fitcv_user:your_secure_password@localhost:5432/fitcv_db
```

## 3. 스키마 설치

### 스키마 파일 실행
```bash
# FitCV 프로젝트 루트 디렉토리에서
psql -h localhost -U fitcv_user -d fitcv_db -f infra/db/schema.sql
```

### 설치 확인
```sql
-- 테이블 목록 확인
\dt

-- 인덱스 확인
\di

-- 뷰 확인
\dv

-- 확장 기능 확인
\dx
```

## 4. Docker Compose 사용 (권장)

### docker-compose.yml 설정
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: fitcv_postgres
    environment:
      POSTGRES_DB: fitcv_db
      POSTGRES_USER: fitcv_user
      POSTGRES_PASSWORD: your_secure_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./infra/db/schema.sql:/docker-entrypoint-initdb.d/schema.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U fitcv_user -d fitcv_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: fitcv_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  meilisearch:
    image: getmeili/meilisearch:v1.4
    container_name: fitcv_meilisearch
    ports:
      - "7700:7700"
    environment:
      MEILI_ENV: development
      MEILI_MASTER_KEY: your_master_key
    volumes:
      - meilisearch_data:/meili_data

volumes:
  postgres_data:
  redis_data:
  meilisearch_data:
```

### Docker 실행
```bash
# 서비스 시작
docker-compose up -d postgres redis meilisearch

# 로그 확인
docker-compose logs -f postgres

# 데이터베이스 접속 확인
docker exec -it fitcv_postgres psql -U fitcv_user -d fitcv_db
```

## 5. 마이그레이션 관리

### Alembic 설정 (FastAPI 프로젝트용)
```bash
# Alembic 설치
pip install alembic

# Alembic 초기화
alembic init alembic

# alembic.ini 수정
sqlalchemy.url = postgresql://fitcv_user:your_secure_password@localhost:5432/fitcv_db
```

### 마이그레이션 파일 생성
```bash
# 초기 마이그레이션 생성
alembic revision --autogenerate -m "Initial schema"

# 마이그레이션 적용
alembic upgrade head

# 마이그레이션 롤백
alembic downgrade -1
```

## 6. 성능 모니터링

### 기본 성능 확인 쿼리
```sql
-- 테이블 크기 확인
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 인덱스 사용률 확인
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats
WHERE schemaname = 'public'
ORDER BY n_distinct DESC;

-- 슬로우 쿼리 확인
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

### PostgreSQL 설정 최적화
```sql
-- 메모리 관련 설정
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';

-- 연결 관련 설정
ALTER SYSTEM SET max_connections = '100';
ALTER SYSTEM SET max_worker_processes = '8';

-- 로깅 설정
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_min_duration_statement = '1000';

-- 설정 적용
SELECT pg_reload_conf();
```

## 7. 백업 및 복원

### 백업 생성
```bash
# 전체 데이터베이스 백업
pg_dump -h localhost -U fitcv_user -d fitcv_db > backup_$(date +%Y%m%d_%H%M%S).sql

# 스키마만 백업
pg_dump -h localhost -U fitcv_user -d fitcv_db --schema-only > schema_backup.sql

# 데이터만 백업
pg_dump -h localhost -U fitcv_user -d fitcv_db --data-only > data_backup.sql
```

### 복원
```bash
# 전체 복원
psql -h localhost -U fitcv_user -d fitcv_db_new < backup_20250913_120000.sql

# 특정 테이블만 복원
pg_restore -h localhost -U fitcv_user -d fitcv_db --table=users backup.dump
```

## 8. 문제 해결

### 일반적인 문제들

#### 연결 오류
```bash
# PostgreSQL 서비스 상태 확인
brew services list | grep postgresql
systemctl status postgresql

# 포트 확인
netstat -an | grep 5432
lsof -i :5432
```

#### 권한 오류
```sql
-- 사용자 권한 확인
\du fitcv_user

-- 테이블 권한 부여
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO fitcv_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO fitcv_user;
```

#### 성능 문제
```sql
-- 인덱스 재구성
REINDEX DATABASE fitcv_db;

-- 통계 정보 업데이트
ANALYZE;

-- 자동 VACUUM 설정 확인
SELECT * FROM pg_stat_user_tables WHERE relname IN ('users', 'job_postings');
```

## 9. 보안 고려사항

### 보안 설정
```sql
-- SSL 연결 강제
ALTER SYSTEM SET ssl = 'on';
ALTER SYSTEM SET ssl_cert_file = 'server.crt';
ALTER SYSTEM SET ssl_key_file = 'server.key';

-- 로그인 시도 제한
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
```

### 네트워크 보안
```bash
# pg_hba.conf 설정 (연결 제한)
echo "host fitcv_db fitcv_user 10.0.0.0/8 md5" >> /etc/postgresql/15/main/pg_hba.conf

# 방화벽 설정
sudo ufw allow from 10.0.0.0/8 to any port 5432
```

## 10. 개발 환경 설정

### 테스트 데이터 삽입
```sql
-- 샘플 사용자 생성
INSERT INTO users (email, name, role) VALUES 
('test@example.com', '테스트 사용자', 'user'),
('admin@example.com', '관리자', 'admin');

-- 샘플 회사 생성
INSERT INTO companies (name, description, industry) VALUES 
('테스트 회사', '테스트를 위한 샘플 회사입니다', 'IT');

-- 샘플 채용공고 생성
INSERT INTO job_postings (company_id, source, title, description, is_active) 
SELECT id, 'sample', '백엔드 개발자', 'Python/FastAPI 개발자를 모집합니다', true 
FROM companies WHERE name = '테스트 회사' LIMIT 1;
```

### 개발용 Docker 설정
```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  postgres:
    extends:
      file: docker-compose.yml
      service: postgres
    environment:
      POSTGRES_DB: fitcv_db_dev
      POSTGRES_USER: fitcv_dev
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5433:5432"  # 다른 포트 사용
```

이제 FitCV 프로젝트의 데이터베이스가 완전히 설정되었습니다!
