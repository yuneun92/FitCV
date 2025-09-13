-- =====================================
-- FitCV 프로젝트 DB 스키마 설계
-- PostgreSQL 기준
-- 작성일: 2025-09-13
-- 목적: 사용자 프로필과 채용 공고 매칭을 통한 자동 문서 생성 서비스
-- =====================================

-- 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =====================================
-- 1) 사용자 관리 (Users)
-- =====================================

-- 사용자 기본 정보
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    oauth_provider VARCHAR(50), -- google, github, linkedin 등
    oauth_id VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user', -- user, admin, company
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 프로필
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    objective TEXT, -- 희망 직무/목표
    location VARCHAR(100), -- 희망 근무지
    salary_min INTEGER, -- 희망 연봉 최소
    salary_max INTEGER, -- 희망 연봉 최대
    years_of_experience INTEGER DEFAULT 0,
    bio TEXT, -- 자기소개
    portfolio_url TEXT,
    github_url TEXT,
    linkedin_url TEXT,
    website_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 스킬
CREATE TABLE user_skills (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    skill_level VARCHAR(20) NOT NULL, -- beginner, intermediate, advanced, expert
    years_experience INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT false, -- 주력 스킬 여부
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 경력
CREATE TABLE user_experiences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    company_name VARCHAR(200) NOT NULL,
    position VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE, -- NULL이면 현재 재직중
    is_current BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 학력
CREATE TABLE user_educations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    institution_name VARCHAR(200) NOT NULL,
    degree VARCHAR(100), -- 학위
    major VARCHAR(100), -- 전공
    gpa DECIMAL(3,2), -- 학점
    start_date DATE,
    end_date DATE,
    is_current BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 프로젝트
CREATE TABLE user_projects (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    tech_stack TEXT[], -- 사용 기술 스택 배열
    project_url TEXT,
    github_url TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================
-- 2) 채용 공고 관리 (Job Postings)
-- =====================================

-- 회사 정보
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    industry VARCHAR(100),
    size_category VARCHAR(50), -- startup, small, medium, large
    location VARCHAR(200),
    website_url TEXT,
    logo_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 채용 공고
CREATE TABLE job_postings (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    external_id VARCHAR(255), -- 외부 API의 공고 ID
    source VARCHAR(50) NOT NULL, -- saramin, worknet, greenhouse, lever
    title VARCHAR(300) NOT NULL,
    description TEXT,
    requirements TEXT,
    preferred_qualifications TEXT,
    responsibilities TEXT,
    benefits TEXT,
    location VARCHAR(200),
    employment_type VARCHAR(50), -- full-time, part-time, contract, internship
    experience_level VARCHAR(50), -- entry, mid, senior, lead
    salary_min INTEGER,
    salary_max INTEGER,
    remote_type VARCHAR(20), -- onsite, remote, hybrid
    apply_url TEXT,
    deadline_date DATE,
    is_active BOOLEAN DEFAULT true,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 유니크 제약 조건
    UNIQUE(external_id, source)
);

-- 채용 공고 필요 스킬
CREATE TABLE job_skills (
    id SERIAL PRIMARY KEY,
    job_posting_id INTEGER REFERENCES job_postings(id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    is_required BOOLEAN DEFAULT true, -- 필수/우대 구분
    proficiency_level VARCHAR(20), -- 요구 숙련도
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 채용 공고 태그 (자동 추출된 키워드)
CREATE TABLE job_tags (
    id SERIAL PRIMARY KEY,
    job_posting_id INTEGER REFERENCES job_postings(id) ON DELETE CASCADE,
    tag_name VARCHAR(100) NOT NULL,
    tag_type VARCHAR(50), -- keyword, technology, industry, location 등
    confidence_score DECIMAL(3,2), -- AI 추출 신뢰도
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================
-- 3) 매칭 및 분석 결과
-- =====================================

-- 사용자-공고 매칭 결과
CREATE TABLE user_job_matches (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    job_posting_id INTEGER REFERENCES job_postings(id) ON DELETE CASCADE,
    overall_score DECIMAL(5,2) NOT NULL, -- 전체 매칭 점수 (0-100)
    skill_match_score DECIMAL(5,2), -- 스킬 매칭 점수
    experience_match_score DECIMAL(5,2), -- 경력 매칭 점수
    location_match_score DECIMAL(5,2), -- 지역 매칭 점수
    salary_match_score DECIMAL(5,2), -- 연봉 매칭 점수
    matching_details JSONB, -- 상세 매칭 정보 (JSON 형태)
    is_bookmarked BOOLEAN DEFAULT false,
    is_applied BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 복합 유니크 제약 조건
    UNIQUE(user_id, job_posting_id)
);

-- 인재상 추출 결과
CREATE TABLE company_personas (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    job_posting_id INTEGER REFERENCES job_postings(id),
    persona_type VARCHAR(50), -- ideal_candidate, company_culture, requirements
    extracted_content TEXT NOT NULL,
    keywords TEXT[], -- 추출된 키워드 배열
    confidence_score DECIMAL(3,2),
    extraction_method VARCHAR(50), -- llm_gpt4, llm_claude, nlp_spacy
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================
-- 4) 자소서/포트폴리오 생성
-- =====================================

-- 프롬프트 템플릿
CREATE TABLE prompt_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    template_content TEXT NOT NULL,
    document_type VARCHAR(50), -- cover_letter, portfolio, resume
    tone VARCHAR(50), -- professional, casual, creative
    version VARCHAR(20) DEFAULT '1.0',
    is_active BOOLEAN DEFAULT true,
    usage_count INTEGER DEFAULT 0,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 생성된 문서
CREATE TABLE generated_documents (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    job_posting_id INTEGER REFERENCES job_postings(id),
    document_type VARCHAR(50) NOT NULL, -- cover_letter, portfolio, resume
    title VARCHAR(300),
    content TEXT NOT NULL,
    format VARCHAR(10) DEFAULT 'markdown', -- markdown, html, plain_text
    prompt_template_id INTEGER REFERENCES prompt_templates(id),
    generation_parameters JSONB, -- tone, length, style 등 생성 파라미터
    word_count INTEGER,
    estimated_reading_time INTEGER, -- 예상 읽기 시간 (분)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 문서 버전 관리
CREATE TABLE document_versions (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES generated_documents(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    content TEXT NOT NULL,
    change_summary TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(document_id, version_number)
);

-- =====================================
-- 5) 피드백 및 평가
-- =====================================

-- 사용자 피드백
CREATE TABLE user_feedback (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    document_id INTEGER REFERENCES generated_documents(id),
    job_posting_id INTEGER REFERENCES job_postings(id),
    feedback_type VARCHAR(50), -- rating, text, suggestion
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback_text TEXT,
    category VARCHAR(50), -- content_quality, relevance, tone, length
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 문서 리뷰 및 개선 제안
CREATE TABLE document_reviews (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES generated_documents(id) ON DELETE CASCADE,
    reviewer_type VARCHAR(50), -- ai, human, system
    review_content TEXT,
    suggestions JSONB, -- 개선 제안 목록
    review_score DECIMAL(3,2), -- 리뷰 점수
    review_categories TEXT[], -- 리뷰 카테고리
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================
-- 6) 시스템 관리
-- =====================================

-- 외부 API 호출 로그
CREATE TABLE api_call_logs (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL, -- saramin, worknet, openai, claude
    endpoint VARCHAR(300),
    request_method VARCHAR(10),
    request_params JSONB,
    response_status INTEGER,
    response_time_ms INTEGER,
    error_message TEXT,
    user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 시스템 작업 큐 (비동기 작업 관리)
CREATE TABLE job_queue (
    id SERIAL PRIMARY KEY,
    job_type VARCHAR(100) NOT NULL, -- collect_jobs, generate_document, send_email
    priority INTEGER DEFAULT 0,
    payload JSONB NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    error_message TEXT,
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 사용자 세션 관리
CREATE TABLE user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    user_agent TEXT,
    ip_address INET,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 파일 업로드 관리
CREATE TABLE uploaded_files (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    original_filename VARCHAR(300) NOT NULL,
    stored_filename VARCHAR(300) NOT NULL,
    file_type VARCHAR(50),
    file_size_bytes INTEGER,
    mime_type VARCHAR(100),
    storage_path TEXT NOT NULL,
    is_public BOOLEAN DEFAULT false,
    upload_purpose VARCHAR(100), -- profile_image, resume, portfolio
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================
-- 7) 회사 인사이트 (핵심 인재상 및 합격자 후기)
-- =====================================

-- 회사 핵심 인재상 (집계/큐레이션된 버전)
CREATE TABLE company_core_personas (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL, -- 예: '핵심 인재상', '문화/가치'
    summary TEXT NOT NULL,
    attributes JSONB, -- 핵심 역량, 성향, 가치관 등 구조화된 필드
    keywords TEXT[],
    source_type VARCHAR(50) DEFAULT 'aggregated', -- manual, scraped, aggregated, llm
    source_refs JSONB, -- [{url, title, collected_at}, ...]
    confidence_score DECIMAL(3,2),
    language VARCHAR(10), -- ko, en 등
    version VARCHAR(20) DEFAULT '1.0',
    is_active BOOLEAN DEFAULT true,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 합격자 후기 / 인터뷰 경험 등 외부 컨텐츠(스크래핑)
CREATE TABLE company_success_stories (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    job_posting_id INTEGER REFERENCES job_postings(id),
    source_name VARCHAR(100), -- 블로그/커뮤니티/유튜브 등
    source_url TEXT NOT NULL,
    author_name VARCHAR(200),
    author_profile_url TEXT,
    posted_at TIMESTAMP,
    title VARCHAR(300),
    content TEXT, -- 정제된 텍스트(HTML 제거)
    content_html TEXT, -- 원문 HTML(가능시)
    language VARCHAR(10), -- ko, en 등
    sentiment VARCHAR(20), -- positive, neutral, negative
    rating INTEGER, -- 별점 등(가능시)
    keywords TEXT[],
    categories TEXT[], -- interview, experience, culture 등
    metrics JSONB, -- {views, likes, comments, shares}
    extraction_metadata JSONB, -- 크롤링/파싱 메타데이터
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, source_url)
);

-- =====================================
-- 인덱스 설계 (성능 최적화)
-- =====================================

-- 기본 성능 인덱스
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active, created_at DESC);

-- 채용 공고 관련 인덱스
CREATE INDEX idx_job_postings_active ON job_postings(is_active, created_at DESC);
CREATE INDEX idx_job_postings_location ON job_postings(location) WHERE is_active = true;
CREATE INDEX idx_job_postings_source ON job_postings(source, external_id);
CREATE INDEX idx_job_postings_company ON job_postings(company_id) WHERE is_active = true;

-- 매칭 관련 인덱스
CREATE INDEX idx_user_job_matches_user ON user_job_matches(user_id, overall_score DESC);
CREATE INDEX idx_user_job_matches_job ON user_job_matches(job_posting_id, overall_score DESC);
CREATE INDEX idx_user_job_matches_bookmarked ON user_job_matches(user_id, is_bookmarked) WHERE is_bookmarked = true;

-- 사용자 프로필 관련 인덱스
CREATE INDEX idx_user_skills_user ON user_skills(user_id, is_primary DESC);
CREATE INDEX idx_user_skills_primary ON user_skills(user_id) WHERE is_primary = true;
CREATE INDEX idx_user_experiences_user ON user_experiences(user_id, start_date DESC);
CREATE INDEX idx_user_projects_user ON user_projects(user_id, start_date DESC);

-- 문서 생성 관련 인덱스
CREATE INDEX idx_generated_documents_user ON generated_documents(user_id, created_at DESC);
CREATE INDEX idx_generated_documents_job ON generated_documents(job_posting_id, created_at DESC);
CREATE INDEX idx_document_versions_doc ON document_versions(document_id, version_number DESC);

-- 시스템 로그 관련 인덱스
CREATE INDEX idx_api_logs_service_time ON api_call_logs(service_name, created_at DESC);
CREATE INDEX idx_api_logs_user_time ON api_call_logs(user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX idx_job_queue_status_priority ON job_queue(status, priority DESC, scheduled_at);

-- 전문 검색을 위한 GIN 인덱스 (PostgreSQL 전용)
CREATE INDEX idx_job_postings_fulltext ON job_postings 
    USING GIN(to_tsvector('korean', COALESCE(title, '') || ' ' || COALESCE(description, '')));
CREATE INDEX idx_companies_fulltext ON companies 
    USING GIN(to_tsvector('korean', COALESCE(name, '') || ' ' || COALESCE(description, '')));

-- 회사 인사이트 관련 인덱스
CREATE INDEX idx_company_core_personas_company ON company_core_personas(company_id, is_active);
CREATE INDEX idx_company_core_personas_fulltext ON company_core_personas 
    USING GIN(to_tsvector('korean', COALESCE(title,'') || ' ' || COALESCE(summary,'')));
CREATE INDEX idx_success_stories_company_date ON company_success_stories(company_id, posted_at DESC);
CREATE INDEX idx_success_stories_fulltext ON company_success_stories 
    USING GIN(to_tsvector('korean', COALESCE(title,'') || ' ' || COALESCE(content,'')));

-- 유사도 검색을 위한 trigram 인덱스
CREATE INDEX idx_job_postings_title_trgm ON job_postings USING GIN(title gin_trgm_ops);
CREATE INDEX idx_companies_name_trgm ON companies USING GIN(name gin_trgm_ops);

-- =====================================
-- 트리거 함수 (자동 업데이트)
-- =====================================

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language plpgsql;

-- updated_at 트리거 생성
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_postings_updated_at BEFORE UPDATE ON job_postings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_generated_documents_updated_at BEFORE UPDATE ON generated_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================
-- 뷰 (Views) - 자주 사용하는 조인 쿼리
-- =====================================

-- 사용자 완전 프로필 뷰
CREATE VIEW user_complete_profiles AS
SELECT 
    u.id,
    u.name,
    u.email,
    u.is_active,
    up.objective,
    up.location,
    up.salary_min,
    up.salary_max,
    up.years_of_experience,
    up.bio,
    up.portfolio_url,
    up.github_url,
    up.linkedin_url,
    array_agg(DISTINCT us.skill_name) FILTER (WHERE us.skill_name IS NOT NULL) as skills,
    array_agg(DISTINCT ue.company_name) FILTER (WHERE ue.company_name IS NOT NULL) as companies
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN user_skills us ON u.id = us.user_id
LEFT JOIN user_experiences ue ON u.id = ue.user_id
GROUP BY u.id, u.name, u.email, u.is_active, up.objective, up.location, 
         up.salary_min, up.salary_max, up.years_of_experience, up.bio, 
         up.portfolio_url, up.github_url, up.linkedin_url;

-- 활성 채용공고 상세 뷰
CREATE VIEW active_job_postings_detail AS
SELECT 
    jp.id,
    jp.title,
    jp.description,
    jp.location,
    jp.employment_type,
    jp.experience_level,
    jp.salary_min,
    jp.salary_max,
    jp.remote_type,
    jp.apply_url,
    jp.deadline_date,
    jp.view_count,
    jp.created_at,
    c.name as company_name,
    c.industry,
    c.size_category,
    c.website_url,
    array_agg(DISTINCT js.skill_name) FILTER (WHERE js.skill_name IS NOT NULL) as required_skills,
    array_agg(DISTINCT jt.tag_name) FILTER (WHERE jt.tag_name IS NOT NULL) as tags
FROM job_postings jp
LEFT JOIN companies c ON jp.company_id = c.id
LEFT JOIN job_skills js ON jp.id = js.job_posting_id
LEFT JOIN job_tags jt ON jp.id = jt.job_posting_id
WHERE jp.is_active = true
GROUP BY jp.id, jp.title, jp.description, jp.location, jp.employment_type, 
         jp.experience_level, jp.salary_min, jp.salary_max, jp.remote_type,
         jp.apply_url, jp.deadline_date, jp.view_count, jp.created_at,
         c.name, c.industry, c.size_category, c.website_url;

-- =====================================
-- 초기 데이터 삽입 (기본 설정)
-- =====================================

-- 기본 프롬프트 템플릿 삽입
INSERT INTO prompt_templates (name, description, template_content, document_type, tone) VALUES
('기본 자소서 템플릿', '일반적인 자기소개서 작성을 위한 기본 템플릿', 
 '안녕하세요. {{user_name}}입니다.\n\n{{company_name}}의 {{position_title}} 포지션에 지원하게 되었습니다.\n\n{{user_objective}}\n\n감사합니다.', 
 'cover_letter', 'professional'),
('창의적 자소서 템플릿', '창의적이고 독특한 자기소개서 작성 템플릿', 
 '# {{user_name}}의 이야기\n\n{{company_name}}와 함께 성장하고 싶은 {{user_name}}입니다.\n\n{{user_story}}', 
 'cover_letter', 'creative'),
('기본 이력서 템플릿', '표준 이력서 형식의 템플릿', 
 '# {{user_name}}\n\n## 연락처\n{{contact_info}}\n\n## 경력\n{{experiences}}\n\n## 스킬\n{{skills}}', 
 'resume', 'professional');

-- 기본 작업 유형 예시 (job_queue에서 사용)
-- 실제 작업은 애플리케이션에서 추가됨

COMMENT ON TABLE users IS '사용자 기본 정보 테이블';
COMMENT ON TABLE user_profiles IS '사용자 프로필 상세 정보';
COMMENT ON TABLE user_skills IS '사용자 보유 스킬 및 숙련도';
COMMENT ON TABLE user_experiences IS '사용자 경력 사항';
COMMENT ON TABLE user_educations IS '사용자 학력 사항';
COMMENT ON TABLE user_projects IS '사용자 프로젝트 이력';
COMMENT ON TABLE companies IS '회사 정보';
COMMENT ON TABLE job_postings IS '채용 공고 정보';
COMMENT ON TABLE job_skills IS '채용 공고별 요구 스킬';
COMMENT ON TABLE job_tags IS '채용 공고 태그 (AI 추출)';
COMMENT ON TABLE user_job_matches IS '사용자-채용공고 매칭 결과';
COMMENT ON TABLE company_personas IS '회사별 인재상 추출 결과';
COMMENT ON TABLE company_core_personas IS '회사 핵심 인재상(집계/큐레이션)';
COMMENT ON TABLE company_success_stories IS '합격자 후기/인터뷰 경험(스크래핑)';
COMMENT ON TABLE prompt_templates IS 'LLM 프롬프트 템플릿';
COMMENT ON TABLE generated_documents IS '생성된 문서 (자소서, 이력서 등)';
COMMENT ON TABLE document_versions IS '문서 버전 관리';
COMMENT ON TABLE user_feedback IS '사용자 피드백';
COMMENT ON TABLE document_reviews IS '문서 리뷰 및 개선 제안';
COMMENT ON TABLE api_call_logs IS '외부 API 호출 로그';
COMMENT ON TABLE job_queue IS '비동기 작업 큐';
COMMENT ON TABLE user_sessions IS '사용자 세션 관리';
COMMENT ON TABLE uploaded_files IS '업로드된 파일 관리';

-- 스키마 생성 완료
SELECT 'FitCV 데이터베이스 스키마 생성이 완료되었습니다.' as status;
