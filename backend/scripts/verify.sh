#!/usr/bin/env bash

# 验证觅诗后端项目结构

set -euo pipefail

BACKEND_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SQL_ROOT="$(cd "$(dirname "$0")/../.." && pwd)/sql"

compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose "$@"
    elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        return 127
    fi
}

echo "🔍 验证觅诗后端项目结构..."

# 检查必要目录
required_dirs=(
    "$BACKEND_ROOT/cmd/server"
    "$BACKEND_ROOT/internal/config"
    "$BACKEND_ROOT/internal/server"
    "$BACKEND_ROOT/internal/database"
    "$BACKEND_ROOT/internal/cache"
    "$BACKEND_ROOT/internal/handler"
    "$BACKEND_ROOT/internal/service"
    "$BACKEND_ROOT/internal/model"
    "$BACKEND_ROOT/pkg/middleware"
    "$BACKEND_ROOT/pkg/util"
    "$BACKEND_ROOT/pkg/response"
    "$BACKEND_ROOT/api"
    "$BACKEND_ROOT/scripts"
    "$SQL_ROOT"
    "$SQL_ROOT/seeds"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ 目录存在: $dir"
    else
        echo "❌ 目录缺失: $dir"
        exit 1
    fi
done

# 检查必要文件
required_files=(
    "$BACKEND_ROOT/cmd/server/main.go"
    "$BACKEND_ROOT/internal/config/config.go"
    "$BACKEND_ROOT/internal/server/server.go"
    "$BACKEND_ROOT/internal/database/database.go"
    "$BACKEND_ROOT/internal/cache/cache.go"
    "$BACKEND_ROOT/internal/handler/health.go"
    "$BACKEND_ROOT/go.mod"
    "$BACKEND_ROOT/go.sum"
    "$BACKEND_ROOT/config.yaml"
    "$BACKEND_ROOT/.env.example"
    "$BACKEND_ROOT/docker-compose.yml"
    "$BACKEND_ROOT/Dockerfile"
    "$BACKEND_ROOT/Makefile"
    "$BACKEND_ROOT/scripts/init.sh"
    "$BACKEND_ROOT/scripts/e2e-web.sh"
    "$BACKEND_ROOT/scripts/verify.sh"
    "$SQL_ROOT/init-database-v1.sql"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ 文件存在: $file"
    else
        echo "❌ 文件缺失: $file"
        exit 1
    fi
done

# 检查Go模块
if [ -f "$BACKEND_ROOT/go.mod" ]; then
    echo "✅ Go模块文件存在"
    module_name=$(grep '^module' "$BACKEND_ROOT/go.mod" | awk '{print $2}')
    echo "   模块名称: $module_name"
else
    echo "❌ Go模块文件缺失"
    exit 1
fi

# 检查Docker Compose配置
if command -v docker-compose &> /dev/null || (command -v docker >/dev/null 2>&1 && docker compose version &> /dev/null); then
    echo "✅ Docker Compose可用"
    
    # 检查docker-compose.yml语法
    if (cd "$BACKEND_ROOT" && compose config -q &> /dev/null); then
        echo "✅ docker-compose.yml语法正确"
    else
        echo "⚠️  docker-compose.yml语法可能有问题"
    fi
else
    echo "⚠️  Docker Compose不可用"
fi

echo ""
echo "🎉 项目结构验证通过！"
echo ""
echo "📋 项目统计："
echo "   目录: ${#required_dirs[@]}个"
echo "   文件: ${#required_files[@]}个"
echo ""
echo "🐶 觅诗后端框架搭建完成！"
