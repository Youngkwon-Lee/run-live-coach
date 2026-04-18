# OpenClaw Integration Plan

## Trigger
- 새 run_sessions row 생성 시 webhook 또는 polling으로 OpenClaw 실행

## Agent output format
1) 런 요약(거리·시간·페이스·고도·평균/최대심박)
2) 전문가 분석(페이스 패턴, 심박 드리프트 추정)
3) 부하/회복 코멘트(최근 7일)
4) 다음 런 처방(습관유지 우선)
5) SNS 초안 2종

## Cron fallback
- direct ingest 실패 시 기존 Strava cron 유지

## Channel
- Discord thread: #idea-dawn-run-tracker-sns-20260414
