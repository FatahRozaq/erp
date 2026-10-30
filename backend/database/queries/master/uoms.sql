-- name: GetUomByGuid :one
SELECT id, guid, tenant_guid, code, name, status,
       created_at, created_by, updated_at, updated_by,
       deleted_at, deleted_by, version
FROM master.uoms
WHERE tenant_guid = sqlc.arg(tenant_guid)
  AND guid = sqlc.arg(guid)
  AND deleted_at IS NULL
LIMIT 1;
