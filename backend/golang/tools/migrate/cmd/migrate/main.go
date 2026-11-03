package main

import (
	"context"
	"flag"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"erp.local/tools/migrate/internal/migration"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	root := flag.String("dir", "backend/database", "database directory containing plan.json and migrations")
	owner := flag.String("owner", "", "database owner from plan.json")
	action := flag.String("action", "status", "status or apply")
	timeout := flag.Duration("timeout", 2*time.Minute, "total connection/lock/migration deadline")
	flag.Parse()
	if (*action != "status" && *action != "apply") || *owner == "" || *timeout <= 0 || flag.NArg() != 0 {
		logger.Error("invalid arguments")
		os.Exit(2)
	}
	dsn := os.Getenv("ERP_MIGRATION_DSN")
	if dsn == "" {
		logger.Error("ERP_MIGRATION_DSN is required")
		os.Exit(2)
	}
	plan, err := migration.Load(*root, *owner)
	if err != nil {
		logger.Error("invalid plan", "error", err.Error())
		os.Exit(1)
	}
	signalCtx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	ctx, cancel := context.WithTimeout(signalCtx, *timeout)
	defer cancel()
	result, err := migration.Run(ctx, dsn, plan, *action == "apply", logger)
	if err != nil {
		logger.Error("migration_stopped", "owner", *owner, "error", err.Error())
		os.Exit(1)
	}
	logger.Info("migration_complete", "owner", *owner, "action", *action, "applied", result.Applied, "pending", result.Pending)
}
