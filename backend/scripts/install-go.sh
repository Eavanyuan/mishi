#!/bin/bash

# Go安装脚本（macOS）

set -e

echo "🐶 安装Go 1.21+..."

# 检查是否已安装
if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    GO_MAJOR=$(echo $GO_VERSION | cut -d. -f1)
    GO_MINOR=$(echo $GO_VERSION | cut -d. -f2)
    
    if [ "$GO_MAJOR" -gt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -ge 21 ]); then
        echo "✅ Go已安装，版本: $GO_VERSION"
        exit 0
    else
        echo "⚠️  Go版本过低: $GO_VERSION，需要1.21+"
    fi
fi

# 检测操作系统
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "操作系统: $OS, 架构: $ARCH"

# macOS安装
if [ "$OS" = "Darwin" ]; then
    echo "使用Homebrew安装Go..."
    
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew未安装，请先安装Homebrew"
        echo "   安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    # 安装Go
    echo "正在安装Go..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install go
    
    # 验证安装
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        echo "✅ Go安装成功，版本: $GO_VERSION"
    else
        echo "❌ Go安装失败"
        exit 1
    fi

# Linux安装
elif [ "$OS" = "Linux" ]; then
    echo "使用官方二进制包安装Go..."
    
    # 下载Go
    GO_VERSION="1.21.0"
    GO_ARCH=""
    
    case "$ARCH" in
        x86_64|amd64)
            GO_ARCH="amd64"
            ;;
        arm64|aarch64)
            GO_ARCH="arm64"
            ;;
        *)
            echo "❌ 不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    
    echo "下载Go $GO_VERSION..."
    wget -q "https://golang.org/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
    # 解压
    echo "解压到/usr/local..."
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    rm "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
    # 设置环境变量
    if ! grep -q "/usr/local/go/bin" "$HOME/.bashrc"; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    
    # 验证安装
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        echo "✅ Go安装成功，版本: $GO_VERSION"
        echo "⚠️  请重新打开终端或运行: source ~/.bashrc"
    else
        echo "❌ Go安装失败"
        exit 1
    fi

else
    echo "❌ 不支持的操作系统: $OS"
    echo "请手动从 https://golang.org/dl/ 下载安装Go 1.21+"
    exit 1
fi

echo ""
echo "🎉 Go安装完成！"
echo "运行以下命令验证项目:"
echo "  cd /Users/yuanyuan/Documents/workspace/mishi/backend"
echo "  ./scripts/init.sh"
echo "  make docker-up"
echo "  make build"