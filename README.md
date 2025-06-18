# 🏠 租房系统 - Docker化云端部署

## 📋 项目简介
这是一个基于Docker的现代化租房管理系统，包含H5移动端和管理后台，支持自动化CI/CD部署到AWS云端。

## 🏗️ 系统架构
- **后端**: Java SpringBoot + JDK 17
  - Admin API (管理后台) - 端口8080  
  - App API (移动端) - 端口8081
- **前端**: Vue 3 + TypeScript
  - H5移动端
  - 管理后台
- **数据**: MySQL 8.0 + Redis + MinIO
- **代理**: Nginx反向代理
- **部署**: Docker + GitHub Actions + AWS EC2

## 🚀 快速启动

### 本地开发环境
```bash
# 克隆项目
git clone https://github.com/yourusername/lease-docker-project.git
cd lease-docker-project

# 配置环境变量
cp .env.example .env

# 启动所有服务
docker-compose up --build -d
```

### 访问地址
- 🌐 H5移动端: http://localhost
- 🔧 管理后台: http://localhost:8888
- 📦 MinIO控制台: http://localhost:9001

## 🌐 生产环境
项目已部署到AWS EC2，通过GitHub Actions实现自动化CI/CD。

## 📞 技术支持
如有问题，请提交Issue或联系项目维护者。
