# Apple Health Direct MVP PRD (Dawn Run Coach)

## 1) Target user
- 개인 러너(매일 새벽런), 기록 자동화 + 코칭 + SNS 초안이 필요한 사용자

## 2) Core pain point
- Strava 의존 없이 Apple Health/Watch 데이터를 직접 수집해 더 빠르고 안정적으로 리포트/코칭을 받고 싶음

## 3) Success KPI (MVP)
- 러닝 종료 후 3분 내 Discord 자동 요약 도착률 95%+
- 주 5회 이상 러닝에서 자동 수집 성공률 95%+

## 4) MVP Must-have (3)
1. iOS 앱(HealthKit 권한)에서 Workout/HR/거리/시간 수집
2. 백엔드(Webhook/API)로 세션 데이터 전송 + 저장
3. OpenClaw 자동 리포트/코칭/SNS 초안 생성 및 Discord 전달

## 5) Out of scope (3)
1. 초단위 라이브 코칭(완전 실시간 음성)
2. 의료적 진단/부상 예측
3. 다중 사용자/팀 대시보드

---

## Architecture (MVP)
- Apple Watch/HealthKit → iOS Companion App
- iOS App → Backend API (signed request)
- Backend DB (run sessions)
- OpenClaw scheduled/triggered analysis → Discord thread post

## Data fields (minimum)
- run_id, start_at, end_at, distance_m, moving_time_s, elevation_gain_m
- avg_hr, max_hr, splits(optional 1km)
- device_source(Apple Watch)

## Security
- HealthKit 최소 권한 원칙
- API key + request signature
- PII 최소 저장(위치 원본/정밀 좌표는 기본 비저장)

## Delivery plan
### Week 1
- iOS HealthKit read PoC
- workout 종료 이벤트 기준 데이터 추출

### Week 2
- backend ingest API + DB schema
- OpenClaw 연동(요약/분석/SNS 템플릿)

### Week 3
- 안정화(재시도/중복방지), TestFlight 내부 배포
- 운영 전환(기존 Strava 파이프라인은 fallback)

## Backlog (stacked)
- stack-0: PRD/운영정책/보안정책
- stack-1: 데이터 모델 + ingest API
- stack-2: iOS HealthKit collector
- stack-3: OpenClaw 분석 프롬프트 + Discord 전달

## Risks
- iOS 백그라운드 전달 타이밍 변동
- HealthKit 권한 거부 시 수집 실패
- 초기에는 split/cadence 필드 누락 가능

## Rollback
- direct ingest 실패 시 기존 Strava cron 자동 fallback 유지
