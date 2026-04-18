# iOS HealthKit Implementation Plan (MVP)

## Required permissions
- HKWorkoutType.workoutType()
- HKQuantityType(.heartRate)
- HKQuantityType(.distanceWalkingRunning)
- HKQuantityType(.runningSpeed) (optional)

## Flow
1. App first launch: 권한 요청
2. 최근 24h Running workout 조회
3. workout + 심박 통계(avg/max) + 거리/시간 계산
4. JSON payload 생성
5. Ingest API 전송(재시도 3회)

## Delivery timing
- MVP: 앱 열 때 수동 sync 버튼 + 자동 1회
- V1.1: BackgroundTasks로 주기 동기화

## Fail-safe
- 권한 거부 시 UI에서 재요청 안내
- 네트워크 실패 시 로컬 큐 저장 후 재전송

## 구현 템플릿
- 파일: `ios/HealthKitIngestService.swift`
- 포함 내용:
  - 최신 러닝 1건 조회
  - 평균/최대 심박 계산
  - Supabase Edge Function(`runs-ingest`)로 HMAC 서명 전송

### 적용 전 체크
1. `ingestApiKey`, `signingSecret`를 실제 값으로 교체
2. 앱에는 장기 하드코딩 금지(최소 Keychain/원격 주입 사용)
3. 헤더 포함: `Authorization`, `x-api-key`, `x-signature`
