# 构建阶段
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 安装依赖
RUN apk add --no-cache git ca-certificates

# 复制go模块文件
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server ./cmd/server

# 运行阶段
FROM alpine:latest

RUN apk --no-cache add ca-certificates curl tzdata

WORKDIR /root/

# 从构建阶段复制可执行文件
COPY --from=builder /app/server .

# 复制配置文件
COPY config.yaml .env.example ./

# 创建非root用户
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

# 更改文件所有权
RUN chown -R appuser:appgroup /root

USER appuser

# 暴露端口
EXPOSE 8080

# 运行应用
CMD ["./server"]
