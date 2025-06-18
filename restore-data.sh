#!/bin/bash
echo "🔄 开始恢复CentOS7数据到AWS环境..."

# 检查数据文件是否存在
if [ ! -f "data-backup/mysql_data.tar.gz" ]; then
    echo "❌ MySQL数据文件不存在"
    exit 1
fi

if [ ! -f "data-backup/minio_data.tar.gz" ]; then
    echo "❌ MinIO数据文件不存在"
    exit 1
fi

if [ ! -f "data-backup/redis_data.tar.gz" ]; then
    echo "❌ Redis数据文件不存在"
    exit 1
fi

echo "✅ 所有数据文件检查通过"

# 确保Docker服务正在运行
docker-compose down 2>/dev/null

# 创建数据目录
mkdir -p data/mysql data/minio data/redis

# 解压数据文件
echo "📦 解压MySQL数据..."
tar -xzf data-backup/mysql_data.tar.gz -C data/mysql/

echo "📦 解压MinIO数据..."
tar -xzf data-backup/minio_data.tar.gz -C data/minio/

echo "📦 解压Redis数据..."
tar -xzf data-backup/redis_data.tar.gz -C data/redis/

# 设置正确的权限
sudo chown -R 999:999 data/mysql/
sudo chown -R 1000:1000 data/minio/
sudo chown -R 999:999 data/redis/

echo "✅ 数据恢复完成！"
echo "🚀 现在可以启动Docker服务：docker-compose up -d"
