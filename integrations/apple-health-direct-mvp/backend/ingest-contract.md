# Ingest API Contract (MVP)

## Endpoint
`POST /api/runs/ingest`

## Headers
- `x-api-key: <INGEST_API_KEY>`
- `x-signature: <HMAC_SHA256(body, INGEST_SIGNING_SECRET)>`

## Body (JSON)
```json
{
  "external_run_id": "apple-2026-04-17-071452",
  "started_at": "2026-04-16T22:14:52Z",
  "ended_at": "2026-04-16T22:35:42Z",
  "distance_m": 2916.6,
  "moving_time_s": 1259,
  "elevation_gain_m": 26,
  "avg_hr": 136.5,
  "max_hr": 148,
  "cadence_avg": null,
  "splits": [
    {"km": 1, "moving_time_s": 434, "avg_hr": 129.9},
    {"km": 2, "moving_time_s": 431, "avg_hr": 139.8}
  ],
  "device_source": "Apple Watch Ultra"
}
```

## Response
- `200 { "ok": true, "id": "<uuid>" }`
- 중복 `external_run_id`는 upsert 처리
