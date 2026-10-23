#!/bin/bash
# Smoke test: send a webhook payload to the Foreman plugin
# Usage: ./test-webhook.sh [foreman_url] [hmac_secret]

FOREMAN_URL="${1:-http://localhost:3000}"
HMAC_SECRET="${2:-test-secret}"

PAYLOAD=$(cat <<'JSON'
{
  "event": "state_transition",
  "workload_id": "550e8400-e29b-41d4-a716-446655440001",
  "ipa_principal": "mcp/test-host.example.com@EXAMPLE.COM",
  "old_state": "ATTESTING",
  "new_state": "HEALTHY",
  "extra": {
    "verdict": "PASS"
  },
  "per_backend": [
    {"backend": "keylime", "verdict": "PASS"},
    {"backend": "cosign", "verdict": "PASS"},
    {"backend": "falco", "verdict": "PASS"},
    {"backend": "measured_boot", "verdict": "PASS"}
  ],
  "timestamp": "2026-10-23T14:30:00Z"
}
JSON
)

SIGNATURE="sha256=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$HMAC_SECRET" -hex | awk '{print $NF}')"

echo "Sending webhook to $FOREMAN_URL/foreman_arbiter/webhook"
echo "Signature: $SIGNATURE"
echo ""

curl -s -w "\nHTTP %{http_code}\n" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-Arbiter-Signature: $SIGNATURE" \
  -d "$PAYLOAD" \
  "$FOREMAN_URL/foreman_arbiter/webhook"
