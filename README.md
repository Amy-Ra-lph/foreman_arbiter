# foreman_arbiter

Foreman/Satellite plugin that surfaces workload attestation status from [Arbiter Hub](https://github.com/Amy-Ra-lph/arbiter-hub).

## What it does

- Receives HMAC-SHA256 signed webhooks on attestation state transitions
- Maintains per-host attestation sub-status (HEALTHY, ATTESTING, STALE, FAILED, REVOKED)
- Provides a host detail tab with attestation history and per-backend verdicts
- Adds an attestation dashboard with fleet-wide health summary
- Exposes attestation data via Foreman API v2

## Architecture

```
Arbiter Hub                          Foreman / Satellite
+-----------+    webhook (HMAC)     +--------------------+
| Keylime   |--+                    | foreman_arbiter    |
| Cosign    |--+--> POST /attest -->| - webhook receiver |
| Falco     |--+    composite       | - host sub-status  |
| Meas.Boot |--+    verdict         | - dashboard        |
+-----------+                       | - API v2           |
                                    +--------------------+
```

## Requirements

- Foreman >= 3.9 or Red Hat Satellite >= 6.20
- Ruby >= 3.1
- PostgreSQL (JSONB columns)

## Installation

### RPM-based (Satellite)

```
yum install rubygem-foreman_arbiter
foreman-installer
```

### Gem-based (development)

```
gem build foreman_arbiter.gemspec
gem install foreman_arbiter-0.1.0.gem
```

Copy the bundler entry:

```
cp dev/bundler.d/foreman_arbiter.rb /usr/share/foreman/bundler.d/
```

Run migrations:

```
foreman-rake db:migrate
```

## Configuration

In Foreman UI under Administer > Settings > Arbiter Hub:

| Setting | Description | Default |
|---------|-------------|---------|
| `arbiter_hub_url` | Base URL of Arbiter Hub API | (empty) |
| `arbiter_webhook_secret` | HMAC-SHA256 shared secret | (empty) |
| `arbiter_host_match_field` | Match by `ipa_principal` or `fqdn` | `ipa_principal` |

## Webhook format

Arbiter Hub sends POST to `/foreman_arbiter/webhook` with:

```json
{
  "event": "state_transition",
  "workload_id": "550e8400-...",
  "ipa_principal": "HTTP/host.example.com@REALM",
  "new_state": "HEALTHY",
  "extra": { "verdict": "PASS" },
  "per_backend": [
    { "backend": "keylime", "verdict": "PASS" },
    { "backend": "cosign", "verdict": "PASS" }
  ]
}
```

Signed with `X-Arbiter-Signature: sha256=<hmac>` header.

## Development

```
cd dev
docker compose up -d
```

Smoke test:

```
bash dev/test-webhook.sh http://localhost:3000 test-secret
```

## License

GPL-3.0 - see [LICENSE](LICENSE).
