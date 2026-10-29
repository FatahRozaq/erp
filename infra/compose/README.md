# Local infrastructure for B-01

Run from repository root:

```sh
podman-compose -f infra/compose/compose.yaml up --build -d
podman-compose -f infra/compose/compose.yaml down
```

The Compose file exposes Postgres (`localhost:15432`), Redis (`localhost:16379`), NATS JetStream, MinIO, five Go HTTP skeletons, and the Next.js shell on loopback only. Passwords in this file are disposable **local test values**. Do not reuse them outside local development. No migration runs on API startup. B-02 adds migration tooling, owner databases, grants, and event integration; B-03 adds gateway security and readiness. `/health/live` checks process liveness only.
