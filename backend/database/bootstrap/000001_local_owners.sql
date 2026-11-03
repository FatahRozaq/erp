-- Disposable local/CI bootstrap only. Run as cluster administrator with psql.
\set ON_ERROR_STOP on
SELECT 'CREATE ROLE erp_platform_deploy LOGIN PASSWORD ''erp_local_only'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_platform_deploy')
\gexec
SELECT 'CREATE ROLE erp_platform_runtime LOGIN PASSWORD ''erp_local_only'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_platform_runtime')
\gexec
SELECT 'CREATE DATABASE erp_platform' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'erp_platform')
\gexec
SELECT 'CREATE ROLE erp_commercial_deploy LOGIN PASSWORD ''erp_local_only'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_commercial_deploy')
\gexec
SELECT 'CREATE ROLE erp_commercial_runtime LOGIN PASSWORD ''erp_local_only'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_commercial_runtime')
\gexec
SELECT 'CREATE DATABASE erp_commercial' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'erp_commercial')
\gexec
SELECT 'CREATE ROLE erp_operations_deploy LOGIN PASSWORD ''erp_local_only'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_operations_deploy')
\gexec
SELECT 'CREATE ROLE erp_operations_runtime LOGIN PASSWORD ''erp_local_only'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_operations_runtime')
\gexec
SELECT 'CREATE DATABASE erp_operations' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'erp_operations')
\gexec
SELECT 'CREATE ROLE erp_finance_deploy LOGIN PASSWORD ''erp_local_only'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_finance_deploy')
\gexec
SELECT 'CREATE ROLE erp_finance_runtime LOGIN PASSWORD ''erp_local_only'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'erp_finance_runtime')
\gexec
SELECT 'CREATE DATABASE erp_finance' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'erp_finance')
\gexec
\connect erp_platform
REVOKE ALL ON DATABASE erp_platform FROM PUBLIC;
GRANT CONNECT, CREATE ON DATABASE erp_platform TO erp_platform_deploy;
GRANT CONNECT ON DATABASE erp_platform TO erp_platform_runtime;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
\connect erp_commercial
REVOKE ALL ON DATABASE erp_commercial FROM PUBLIC;
GRANT CONNECT, CREATE ON DATABASE erp_commercial TO erp_commercial_deploy;
GRANT CONNECT ON DATABASE erp_commercial TO erp_commercial_runtime;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
\connect erp_operations
REVOKE ALL ON DATABASE erp_operations FROM PUBLIC;
GRANT CONNECT, CREATE ON DATABASE erp_operations TO erp_operations_deploy;
GRANT CONNECT ON DATABASE erp_operations TO erp_operations_runtime;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
\connect erp_finance
REVOKE ALL ON DATABASE erp_finance FROM PUBLIC;
GRANT CONNECT, CREATE ON DATABASE erp_finance TO erp_finance_deploy;
GRANT CONNECT ON DATABASE erp_finance TO erp_finance_runtime;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
