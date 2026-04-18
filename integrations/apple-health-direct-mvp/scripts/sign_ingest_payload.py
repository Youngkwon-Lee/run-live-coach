#!/usr/bin/env python3
import hashlib
import hmac
import json
import os
import sys
import requests

# Usage:
# INGEST_URL=... INGEST_API_KEY=... INGEST_SIGNING_SECRET=... ./sign_ingest_payload.py payload.json

if len(sys.argv) < 2:
    print("usage: sign_ingest_payload.py <payload.json>")
    sys.exit(1)

url = os.environ.get("INGEST_URL")
api_key = os.environ.get("INGEST_API_KEY")
secret = os.environ.get("INGEST_SIGNING_SECRET")

if not url or not api_key or not secret:
    print("missing env: INGEST_URL, INGEST_API_KEY, INGEST_SIGNING_SECRET")
    sys.exit(1)

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload_obj = json.load(f)

raw = json.dumps(payload_obj, ensure_ascii=False, separators=(",", ":"))
signature = hmac.new(secret.encode(), raw.encode(), hashlib.sha256).hexdigest()

res = requests.post(
    url,
    data=raw.encode("utf-8"),
    headers={
        "content-type": "application/json",
        "x-api-key": api_key,
        "x-signature": signature,
    },
    timeout=20,
)

print(res.status_code)
print(res.text)
