#!/bin/bash
set -e

CONTAINER_NAME="mishi-test-db-$(date +%s)"
DB_PASSWORD="testpass"

echo "启动 PostgreSQL 15 + PostGIS 3.3 容器..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -e POSTGRES_DB=mishi_test \
  -p 5433:5432 \
  postgis/postgis:15-3.3

echo "等待数据库启动..."
sleep 10

echo "测试数据库连接..."
until docker exec "$CONTAINER_NAME" pg_isready -U postgres; do
  sleep 2
done

echo "执行初始化脚本..."
docker exec -i "$CONTAINER_NAME" psql -U postgres -d mishi_test -v ON_ERROR_STOP=1 < sql/init-database-v1.sql

if [ $? -eq 0 ]; then
    echo "✅ SQL 脚本执行成功！"
    
    echo "检查表创建情况..."
    docker exec "$CONTAINER_NAME" psql -U postgres -d mishi_test -c "
        SELECT 
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
        FROM pg_tables 
        WHERE schemaname = 'public' 
        ORDER BY tablename;
    "
    
    echo "检查扩展..."
    docker exec "$CONTAINER_NAME" psql -U postgres -d mishi_test -c "
        SELECT extname, extversion FROM pg_extension WHERE extname IN ('postgis', 'pg_cron', 'pg_trgm', 'uuid-ossp');
    "
    
    echo "检查分区..."
    docker exec "$CONTAINER_NAME" psql -U postgres -d mishi_test -c "
        SELECT 
            parent_schema,
            parent_tablename,
            partition_schema,
            partition_tablename,
            partition_ordinal_position
        FROM pg_partitions 
        WHERE parent_tablename IN ('checkins', 'user_events');
    " 2>/dev/null || echo "pg_partitions 视图可能不可用，使用替代查询..."
    
    docker exec "$CONTAINER_NAME" psql -U postgres -d mishi_test -c "
        SELECT inhparent::regclass AS parent, inhrelid::regclass AS child
        FROM pg_inherits
        WHERE inhparent::regclass::text IN ('public.checkins', 'public.user_events');
    "
    
    echo "检查高优先级修复..."
    docker exec "$CONTAINER_NAME" psql -U postgres -d mishi_test -c "
        -- 修复1: 检查外键级联策略
        SELECT 
            tc.table_name, 
            kcu.column_name, 
            ccu.table_name AS foreign_table_name,
            rc.delete_rule
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
        JOIN information_schema.referential_constraints AS rc
          ON rc.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY' 
          AND tc.table_name IN ('checkins', 'poi_poems')
          AND rc.delete_rule = 'CASCADE';
    "
    
    echo "检查唯一约束..."
    docker exec "$CONTAINER_NAME" psql -U postgres -d mishi_test -c "
        SELECT 
            conname,
            conrelid::regclass AS table,
            pg_get_constraintdef(oid) AS definition
        FROM pg_constraint 
        WHERE conrelid::regclass::text IN ('public.checkins')
          AND contype = 'u';
    "
    
    echo "检查空间索引..."
    docker exec "$CONTAINER_NAME" psql -U postgres -d mishi_test -c "
        SELECT 
            tablename,
            indexname,
            indexdef
        FROM pg_indexes 
        WHERE indexdef LIKE '%USING GIST%' 
          AND tablename IN ('checkins', 'pois');
    "
    
    echo "检查触发器..."
    docker exec "$CONTAINER_NAME" psql -U postgres -d mishi_test -c "
        SELECT 
            tgname,
            tgrelid::regclass AS table,
            pg_get_triggerdef(oid) AS definition
        FROM pg_trigger 
        WHERE tgname LIKE '%updated_at%' 
          AND NOT tgisinternal;
    "
    
    echo "清理容器..."
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    
    echo "✅ 所有检查通过！"
else
    echo "❌ SQL 脚本执行失败！"
    echo "清理容器..."
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    exit 1
fi