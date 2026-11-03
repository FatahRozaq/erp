# Local infrastructure for B-01

Install `podman-compose==1.6.0` from `requirements.txt` if the Compose provider is not already available. Run from repository root:

```sh
podman-compose -f infra/compose/compose.yaml up --build -d
podman-compose -f infra/compose/compose.yaml down
```

The Compose file exposes Postgres (`localhost:15432`), Redis (`localhost:16379`), NATS JetStream, MinIO, five Go HTTP skeletons, and the Next.js shell on loopback only. Passwords in this file are disposable **local test values**. Do not reuse them outside local development. No migration runs on API startup. B-02.1 supplies separate migration tooling and owner database/role provisioning through the [migration runbook](../../docs/operations/database-migrations.md); B-02.2 adds event integration; B-03 adds gateway security and readiness. `/health/live` checks process liveness only.
