
# 🏠 房屋租赁管理系统 - AWS EC2 完整部署指南

**中文版**|[日本語版](./README.md)| [English Version](./README_EN.md)

## 🔍 项目了解 - 功能介绍与技术详情
 [lease-system-backend](https://github.com/yukoto0718/lease-system-backend.git)

## 项目背景

**房屋租赁管理系统**是一个基于微服务架构的完整租赁管理平台，采用 **Spring Boot + Vue.js + Docker** 技术栈开发。系统包含用户端H5应用和管理后台，支持房源管理、用户管理、预约看房、合同管理等完整业务流程。

### 技术栈组成

- **前端**: Vue.js H5用户端 + Vue.js管理后台
- **后端**: Spring Boot微服务架构
- **数据库**: MySQL 8.0 + Redis缓存
- **文件存储**: MinIO对象存储
- **Web服务器**: Nginx反向代理
- **容器化**: Docker + Docker Compose
- **CI/CD**: GitHub Actions自动部署

---

## 体验用URL

> 本演示系统部署在 **AWS EC2 (t2.micro)** 免费层实例上，仅供技术展示和学习交流使用。

### 前端访问
**用户端H5页面**: http://57.183.57.12

用户①：`用户名 13112345678 / 密码 123456`
用户②：`用户名 13212345678 / 密码 123456`
用户③：`用户名 13312345678 / 密码 123456`

### 管理后台
**管理系统**: http://57.183.57.12:8888

`用户名：user 密码：密码 123456`

### 文件存储
**MinIO控制台**: http://57.183.57.12:9001

`用户名：minioadmin 密码：minioadmin`

## 部署步骤

### 1.创建AWS EC2实例

**实例配置要求**

>实例名称: lease-production-server
AMI: Amazon Linux 2023 AMI (Free tier eligible)
实例类型: t2.micro (Free tier eligible)
创建安全组：lease-server-sg
存储: 30GB (Free tier)
固定IP: 启用 Allocate Elastic IP address

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|---------|-------------|
| SSH | TCP | 22 | My IP | SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | H5 frontend |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Admin API |
| Custom TCP | TCP | 8081 | 0.0.0.0/0 | App API |
| Custom TCP | TCP | 8888 | 0.0.0.0/0 | Admin frontend |
| Custom TCP | TCP | 9001 | 0.0.0.0/0 | MinIO console |
| Custom TCP | TCP | 8082 | 0.0.0.0/0 | Adminer |
| Custom TCP | TCP | 9000 | 0.0.0.0/0 | MINIO API |


##  第二步：连接EC2并安装基础环境
**2.1 SSH连接**
>powershell# Windows PowerShell
>cd C:\aws-keys\
>ssh -i lease-server-key.pem ec2-user@你的EC2公网IP

**2.2 安装必要软件**
>bash# 更新系统
>sudo yum update -y

安装Docker
>sudo yum install docker -y
>sudo systemctl start docker
>sudo systemctl enable docker
>sudo usermod -a -G docker ec2-user

安装Docker Compose
>sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
>sudo chmod +x /usr/local/bin/docker-compose

安装Git
>sudo yum install git -y

退出以应用Docker组权限
>exit

## 第三步：配置Swap空间（关键步骤）

为什么需要Swap？
t2.micro只有1GB内存，运行7个Docker容器会超出内存限制，导致系统卡死。

**3.1 重新连接并配置Swap**
重新连接
>ssh -i lease-server-key.pem ec2-user@你的EC2公网IP

创建2GB Swap文件
>sudo dd if=/dev/zero of=/swapfile bs=1024 count=2097152
>sudo chmod 600 /swapfile
>sudo mkswap /swapfile
>sudo swapon /swapfile

验证Swap是否生效
>free -h

设置开机自动挂载
>echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab

成功标志：
>Mem:   949Mi    192Mi     69Mi   0.0Ki   686Mi   608Mi
>Swap:  2.0Gi       0B    2.0Gi

## 第四步：克隆项目并配置
**4.1 克隆项目代码**
```bash
# 使用GitHub Token克隆
git clone https://你的用户名:你的Token@github.com/你的用户名/lease-docker-project.git
cd lease-docker-project
```
**4.2 检查配置文件**
```bash
# 检查IP配置是否正确
grep "MINIO_ENDPOINT" docker-compose.fixed.yml
```

查看环境变量
>cat .env

设置数据目录权限
```bash
sudo chown -R 999:999 data/mysql/
sudo chown -R 1000:1000 data/minio/
sudo chown -R 999:999 data/redis/
```

## 第五步：分步部署Docker服务

为什么要分步部署？

避免同时启动7个容器导致内存瞬间耗尽
确保MySQL有足够时间初始化数据库
便于监控资源使用和排查问题


**5.1 启动核心服务**
```bash
# 启动MySQL和Redis
docker-compose -f docker-compose.fixed.yml up -d mysql redis
sleep 60
```

检查状态
>docker ps
>free -h

**5.2 启动数据库管理**
```bash
# 启动Adminer
docker-compose -f docker-compose.fixed.yml up -d adminer
sleep 30
```
**5.3 启动后端服务**
```bash
# 启动Spring Boot应用
docker-compose -f docker-compose.fixed.yml up -d web-admin web-app
sleep 30
```
**5.4 启动存储服务**
```bash
# 启动MinIO
docker-compose -f docker-compose.fixed.yml up -d minio
sleep 30
```
**5.5 启动前端服务**
```bash
# 启动Nginx
docker-compose -f docker-compose.fixed.yml up -d nginx
sleep 30
```
查看最终状态
>docker ps
>free -h
成功标志：7个容器全部运行

## 第六步：验证部署
**6.1 访问服务**
用户端页面: http://你的EC2公网IP
管理后台: http://你的EC2公网IP:8888
MinIO控制台: http://你的EC2公网IP:9001
数据库管理: http://你的EC2公网IP:8082

**6.2 登录数据库管理**
Adminer登录信息：

系统：MySQL
服务器：mysql
用户名：root
密码：Atguigu.123
数据库：lease

**6.3 图片显示修复**
如果图片无法显示，在Adminer中执行：
```sql
sqlUPDATE file_management 
SET url = REPLACE(url, 'http://旧IP:9000', 'http://你的EC2公网IP:9000') 
WHERE url LIKE '%旧IP%';
```
user_info表，blog_graph_info表，graph_info表也需要相应的IP地址修改