# iOS Integration Next Steps

## 1) Xcode 설정
1. `RunIngestConfig.template.xcconfig`를 복사해 `RunIngestConfig.xcconfig` 생성
2. 실제 값 입력
   - `RUN_INGEST_URL`
   - `RUN_INGEST_API_KEY`
   - `RUN_INGEST_SIGNING_SECRET`
3. Target > Build Settings > Base Configuration에 연결

## 2) Info.plist 주입
Info.plist에 아래 키 추가:
- `RUN_INGEST_URL` = `$(RUN_INGEST_URL)`
- `RUN_INGEST_API_KEY` = `$(RUN_INGEST_API_KEY)`
- `RUN_INGEST_SIGNING_SECRET` = `$(RUN_INGEST_SIGNING_SECRET)`

## 3) 호출 코드 예시
```swift
let service = HealthKitIngestService.fromBuildSettings()
Task {
  do {
    try await service.requestPermissions()
    try await service.syncLatestRun()
    print("ingest success")
  } catch {
    print("ingest failed: \(error)")
  }
}
```

## 4) 주의
- API 키/시크릿을 깃에 커밋 금지
- 운영 배포 전에는 최소 Keychain + 원격 교체 구조 권장
- 테스트는 실기기(HealthKit 데이터 존재)에서 진행
