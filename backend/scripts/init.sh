#!/usr/bin/env bash

# 觅诗后端初始化脚本

set -euo pipefail

BACKEND_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BACKEND_ROOT"

echo "🐶 觅诗后端初始化开始..."

# 检查Go是否安装
if ! command -v go &> /dev/null; then
    echo "❌ Go未安装，请先安装Go 1.21+"
    exit 1
fi

# 检查Go版本
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
GO_MAJOR=$(echo $GO_VERSION | cut -d. -f1)
GO_MINOR=$(echo $GO_VERSION | cut -d. -f2)

if [ "$GO_MAJOR" -lt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -lt 21 ]); then
    echo "❌ Go版本需要1.21+，当前版本: $GO_VERSION"
    exit 1
fi

echo "✅ Go版本检查通过: $GO_VERSION"

# 检查Docker是否安装（可选）
if command -v docker &> /dev/null; then
    echo "✅ Docker已安装: $(docker --version | awk '{print $3}' | sed 's/,//')"
else
    echo "⚠️  Docker未安装，将无法使用Docker Compose启动依赖服务"
fi

# 检查Docker Compose是否安装（可选）
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose已安装: $(docker-compose --version | awk '{print $3}' | sed 's/,//')"
elif command -v docker >/dev/null 2>&1 && docker compose version &> /dev/null; then
    echo "✅ Docker Compose已安装: $(docker compose version | awk '{print $4}')"
else
    echo "⚠️  Docker Compose未安装，将无法使用Docker Compose启动依赖服务"
fi

# 下载Go依赖
echo "📦 下载Go依赖..."
go mod download

# 创建配置文件
if [ ! -f ".env" ]; then
    echo "📄 创建.env文件..."
    cp .env.example .env
    echo "✅ .env文件已创建，请根据实际情况修改"
else
    echo "✅ .env文件已存在"
fi

# 创建bin目录
mkdir -p bin

# 构建项目
echo "🔨 构建项目..."
go build -o bin/server ./cmd/server

# 设置执行权限
chmod +x bin/server

echo ""
echo "🎉 初始化完成！"
echo ""
echo "📋 下一步操作："
echo "   1. 修改 .env 文件中的配置（如果需要）"
echo "   2. 启动依赖服务: make docker-up"
echo "   3. 初始化数据库: make db-init"
echo "   4. 导入专题数据: make db-seed"
echo "   5. 校验数据库: make db-verify"
echo "   6. 运行后端服务: make run"
echo "   7. 验证服务: curl http://localhost:8080/health"
echo ""
echo "🐶 觅诗后端已就绪！"
