.PHONY: build run test test-integration test-coverage lint clean docker-up docker-down docker-clean dev-setup db-init db-migrate db-seed db-verify db-clean-reset-tokens generate health dev e2e-web

DB_URL ?= postgres://mishi:mishi_password@localhost:5432/mishi?sslmode=disable
COMPOSE_CMD := $(shell if command -v docker-compose >/dev/null 2>&1; then echo docker-compose; elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then echo docker compose; else echo docker-compose; fi)
SQL_ROOT := $(abspath ../sql)

# Go 相关命令
build:
	@echo "Building server..."
	@go build -o bin/server ./cmd/server

run:
	@set -a; [ -f .env ] && . ./.env; set +a; go run ./cmd/server

test:
	@echo "Running tests..."
	@go test -v ./...

test-integration:
	@echo "Running integration tests (requires TEST_DATABASE_URL or local postgres)..."
	@go test -v ./internal/handler -run '^TestIntegration'

test-coverage:
	@echo "Running tests with coverage..."
	@go test -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html

lint:
	@echo "Running linter..."
	@golangci-lint run

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf bin/
	@rm -f coverage.out coverage.html

# Docker 相关命令
docker-up:
	@echo "Starting Docker Compose..."
	@$(COMPOSE_CMD) up -d

docker-down:
	@echo "Stopping Docker Compose..."
	@$(COMPOSE_CMD) down

docker-clean:
	@echo "Cleaning Docker resources..."
	@$(COMPOSE_CMD) down -v --remove-orphans

# 开发环境设置
dev-setup:
	@echo "Setting up development environment..."
	@cp .env.example .env
	@go mod download

db-init:
	@echo "Running baseline database initialization..."
	@test -f "$(SQL_ROOT)/init-database-v1.sql"
	@psql "$${DATABASE_URL:-$(DB_URL)}" -f "$(SQL_ROOT)/init-database-v1.sql"

db-migrate: db-init
	@echo "Database baseline initialization complete."

db-seed:
	@echo "Running database seed files..."
	@set -e; \
	test -d "$(SQL_ROOT)/seeds"; \
	find "$(SQL_ROOT)/seeds" -maxdepth 1 -name '*.sql' | sort | while IFS= read -r seed; do \
		echo "Applying $$seed"; \
		psql "$${DATABASE_URL:-$(DB_URL)}" -f "$$seed"; \
	done

db-verify:
	@echo "Verifying database tooling and seed assets..."
	@command -v psql >/dev/null 2>&1 || (echo "psql is required" && exit 1)
	@test -f "$(SQL_ROOT)/init-database-v1.sql"
	@test -d "$(SQL_ROOT)/seeds"
	@psql "$${DATABASE_URL:-$(DB_URL)}" -c "SELECT 1;"

db-clean-reset-tokens:
	@echo "Cleaning expired/used password reset tokens..."
	@psql "$${DATABASE_URL:-$(DB_URL)}" -c "DELETE FROM password_reset_tokens WHERE used_at IS NOT NULL OR expires_at < NOW();"

# 代码生成
generate:
	@echo "Generating code..."
	@go generate ./...
	@command -v sqlc >/dev/null 2>&1 && sqlc generate || echo "sqlc not installed; skipped"

# 健康检查
health:
	@echo "Checking service health..."
	@curl -fsS http://localhost:8080/health >/dev/null || (echo "Health check failed" && exit 1)

# 完整开发流程
dev: docker-up build
	@echo "Development environment ready!"
	@echo "Backend server: http://localhost:8080"
	@echo "PostgreSQL: localhost:5432"
	@echo "Redis: localhost:6379"

e2e-web:
	@echo "Running web end-to-end API verification..."
	@./scripts/e2e-web.sh
