#!/bin/bash
echo "🚀 开始AWS t2.micro优化部署..."
echo "💡 这个脚本会分步启动服务，避免内存峰值"

# 停止所有服务
echo "🛑 停止现有服务..."
docker-compose down 2>/dev/null
docker-compose -f docker-compose.micro.yml down 2>/dev/null

# 清理系统缓存
echo "🧹 清理系统缓存..."
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

echo "📊 当前内存状态："
free -h

# 第1阶段：启动基础服务
echo ""
echo "📦 第1阶段：启动基础服务 (MySQL, Redis, MinIO)..."
docker-compose -f docker-compose.micro.yml up -d mysql redis minio

echo "⏰ 等待基础服务启动（90秒）..."
for i in {90..1}; do
    echo -ne "\r等待: $i 秒  "
    sleep 1
done
echo ""

# 检查基础服务状态
echo "🔍 检查基础服务状态..."
docker-compose -f docker-compose.micro.yml ps

echo "📊 第1阶段内存使用："
free -h

# 第2阶段：启动Admin后端
echo ""
echo "⚡ 第2阶段：启动Admin后端服务..."
docker-compose -f docker-compose.micro.yml up -d web-admin

echo "⏰ 等待Admin服务启动（120秒）..."
for i in {120..1}; do
    echo -ne "\r等待: $i 秒  "
    sleep 1
done
echo ""

# 检查Admin服务
echo "🔍 检查Admin服务健康状态..."
if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "✅ Admin服务启动成功"
else
    echo "⚠️  Admin服务可能还在启动中..."
fi

echo "📊 第2阶段内存使用："
free -h

# 第3阶段：启动App后端
echo ""
echo "⚡ 第3阶段：启动App后端服务..."
docker-compose -f docker-compose.micro.yml up -d web-app

echo "⏰ 等待App服务启动（120秒）..."
for i in {120..1}; do
    echo -ne "\r等待: $i 秒  "
    sleep 1
done
echo ""

# 检查App服务
echo "🔍 检查App服务健康状态..."
if curl -f http://localhost:8081/actuator/health > /dev/null 2>&1; then
    echo "✅ App服务启动成功"
else
    echo "⚠️  App服务可能还在启动中..."
fi

echo "📊 第3阶段内存使用："
free -h

# 第4阶段：启动前端服务
echo ""
echo "🌐 第4阶段：启动前端服务 (Nginx)..."
docker-compose -f docker-compose.micro.yml up -d nginx

echo "⏰ 等待Nginx启动（30秒）..."
for i in {30..1}; do
    echo -ne "\r等待: $i 秒  "
    sleep 1
done
echo ""

# 最终状态检查
echo "📊 最终部署状态："
docker-compose -f docker-compose.micro.yml ps

# 显示访问地址
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "你的EC2-IP")
echo ""
echo "🎉 部署完成！访问地址："
echo "=================================="
echo "🌐 H5移动端:     http://$PUBLIC_IP"
echo "🔧 管理后台:     http://$PUBLIC_IP:8888"
echo "📦 MinIO控制台:  http://$PUBLIC_IP:9001"
echo "⚡ Admin API:    http://$PUBLIC_IP:8080/actuator/health"
echo "⚡ App API:      http://$PUBLIC_IP:8081/actuator/health"
echo "=================================="

# 最终内存和容器统计
echo ""
echo "📊 最终系统状态："
echo "内存使用情况："
free -h
echo ""
echo "Docker容器资源使用："
docker stats --no-stream

echo ""
echo "✅ 如果所有服务状态都是 'Up'，部署成功！"
echo "🌐 现在可以用浏览器访问上面的地址测试功能"
