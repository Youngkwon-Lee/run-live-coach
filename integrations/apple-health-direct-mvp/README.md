# Dawn Run Apple Health Direct MVP

Assumptions (can change anytime):
- Repo: `dawn-run-health-direct`
- Backend: Supabase

## Goal
Apple Health(Watch) 러닝 데이터를 Strava 없이 직접 수집해서 Discord 자동 리포트/코칭/SNS 초안을 생성.

## MVP Scope
1. iOS HealthKit 권한 + 최근 러닝 Workout 추출
2. Supabase ingest API + run_sessions 저장
3. OpenClaw가 ingest 데이터 기반 자동 분석/코칭 전송

## Next Actions
- [x] Supabase 테이블 생성 SQL 준비 (`supabase/schema.sql`)
- [x] Ingest Edge Function 스캐폴딩 (`backend/supabase/functions/runs-ingest/index.ts`)
- [ ] iOS 앱 HealthKit Reader 구현
- [ ] OpenClaw ingest→분석 프롬프트 연결
- [ ] TestFlight internal 배포

## Quick start (Supabase)
1. SQL 적용: `supabase/schema.sql`
2. 함수 배포:
   - `supabase functions deploy runs-ingest`
3. 함수 시크릿 설정:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `INGEST_API_KEY`
   - `INGEST_SIGNING_SECRET`
4. 로컬 테스트:
   - `pip install requests`
   - `INGEST_URL=<function-url> INGEST_API_KEY=<key> INGEST_SIGNING_SECRET=<secret> python3 scripts/sign_ingest_payload.py scripts/sample_payload.json`

## Supabase helper (local)

```bash
# inspect the central secret mapping
./scripts/with-central-supabase-env.sh

# health check
./scripts/supabase.sh health

# run SQL after creating rpc function in SQL Editor
./scripts/supabase.sh query "select now();"
```

`supabase/exec_sql.sql` 를 Supabase SQL Editor에서 1회 실행하면 `rpc/exec_sql` 호출이 활성화됩니다.

Local secret handling note:
- canonical local Supabase secrets live in `~/.openclaw/workspace/.secrets/`
- do not store live keys in this repo-local `.env`
- use `./scripts/with-central-supabase-env.sh -- <command>` when a command needs exported env vars
