# 🏠 House Rental Management System - AWS EC2 Complete Deployment Guide

**English Version** |[中文版](./readme_cn.md) | [日本語版](./readme.md)

## 🔍 Project Overview - Features & Technical Details
 [lease-system-backend](https://github.com/yukoto0718/lease-system-backend.git)

## Project Background

**House Rental Management System** is a complete rental management platform based on microservice architecture, developed with **Spring Boot + Vue.js + Docker** technology stack. The system includes H5 user application and management backend, supporting complete business processes such as property management, user management, appointment viewing, contract management, etc.

### Technology Stack

- **Frontend**: Vue.js H5 User App + Vue.js Admin Dashboard
- **Backend**: Spring Boot Microservice Architecture
- **Database**: MySQL 8.0 + Redis Cache
- **File Storage**: MinIO Object Storage
- **Web Server**: Nginx Reverse Proxy
- **Containerization**: Docker + Docker Compose
- **CI/CD**: GitHub Actions Auto Deployment

---

## Demo URLs

> This demonstration system is deployed on **AWS EC2 (t2.micro)** free tier instance for technical showcase and educational purposes only.

### Frontend Access
**H5 User App**: http://57.183.57.12

User①：`Username 13112345678 / Password 123456`
User②：`Username 13212345678 / Password 123456`
User③：`Username 13312345678 / Password 123456`

### Admin Dashboard
**Management System**: http://57.183.57.12:8888

`Username: user / Password: 123456`

### File Storage
**MinIO Console**: http://57.183.57.12:9001

`Username: minioadmin / Password: minioadmin`

## Deployment Steps

### 1. Create AWS EC2 Instance

**Instance Configuration Requirements**

> Instance Name: lease-production-server
> AMI: Amazon Linux 2023 AMI (Free tier eligible)
> Instance Type: t2.micro (Free tier eligible)
> Create Security Group: lease-server-sg
> Storage: 30GB (Free tier)
> Fixed IP: Enable Allocate Elastic IP address

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|---------|-------------|
| SSH | TCP | 22 | My IP | SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | H5 frontend |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Admin API |
| Custom TCP | TCP | 8081 | 0.0.0.0/0 | App API |
| Custom TCP | TCP | 8888 | 0.0.0.0/0 | Admin frontend |
| Custom TCP | TCP | 9001 | 0.0.0.0/0 | MinIO console |
| Custom TCP | TCP | 8082 | 0.0.0.0/0 | Adminer |
| Custom TCP | TCP | 9000 | 0.0.0.0/0 | MinIO API |

## Step 2: Connect to EC2 and Install Basic Environment

**2.1 SSH Connection**
```powershell
# Windows PowerShell
cd C:\aws-keys\
ssh -i lease-server-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
```
**2.2 Install Required Software**
```
bash# Update system
sudo yum update -y
```

Install Docker
```
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
```

Install Docker Compose
```
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Install Git
```
sudo yum install git -y
```

# Exit to apply Docker group permissions
```
exit
```

## Step 3: Configure Swap Space (Critical Step)
Why do we need Swap?
t2.micro only has 1GB memory, running 7 Docker containers will exceed memory limit and cause system freeze.

**3.1 Reconnect and Configure Swap**
```bash
# Reconnect
ssh -i lease-server-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

Create 2GB Swap file
```
sudo dd if=/dev/zero of=/swapfile bs=1024 count=2097152
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Verify Swap is active
```
free -h
```

Set auto-mount on boot
```
echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
Success Indicator:
Mem:   949Mi    192Mi     69Mi   0.0Ki   686Mi   608Mi
Swap:  2.0Gi       0B    2.0Gi
```

## Step 4: Clone Project and Configure
**4.1 Clone Project Code**
```bash
# Clone using GitHub Token
git clone https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/lease-docker-project.git
cd lease-docker-project
```
**4.2 Check Configuration Files**
```bash
# Check IP configuration
grep "MINIO_ENDPOINT" docker-compose.fixed.yml

# View environment variables
cat .env

# Set data directory permissions
sudo chown -R 999:999 data/mysql/
sudo chown -R 1000:1000 data/minio/
sudo chown -R 999:999 data/redis/
```
## Step 5: Deploy Docker Services in Stages
Why deploy in stages?

Avoid memory exhaustion from starting 7 containers simultaneously
Ensure MySQL has enough time to initialize database
Easy to monitor resource usage and troubleshoot issues

**5.1 Start Core Services**
```bash
# Start MySQL and Redis
docker-compose -f docker-compose.fixed.yml up -d mysql redis
sleep 60
```

Check status
```
docker ps
free -h
```
**5.2 Start Database Management**
```bash
# Start Adminer
docker-compose -f docker-compose.fixed.yml up -d adminer
sleep 30
```
**5.3 Start Backend Services**
```bash
# Start Spring Boot applications
docker-compose -f docker-compose.fixed.yml up -d web-admin web-app
sleep 30
```
**5.4 Start Storage Service**
```bash
# Start MinIO
docker-compose -f docker-compose.fixed.yml up -d minio
sleep 30
```
**5.5 Start Frontend Service**
```bash
# Start Nginx
docker-compose -f docker-compose.fixed.yml up -d nginx
sleep 30
```

Check final status
```
docker ps
free -h
```
Success Indicator: All 7 containers running

## Step 6: Verify Deployment
**6.1 Access Services**
```
User App: http://YOUR_EC2_PUBLIC_IP
Admin Dashboard: http://YOUR_EC2_PUBLIC_IP:8888
MinIO Console: http://YOUR_EC2_PUBLIC_IP:9001
Database Management: http://YOUR_EC2_PUBLIC_IP:8082
```

**6.2 Database Management Login**
```
Adminer Login Credentials:
System: MySQL
Server: mysql
Username: root
Password: Atguigu.123
Database: lease
```

**6.3 Fix Image Display**
If images cannot display, execute in Adminer:
```sql
UPDATE file_management 
SET url = REPLACE(url, 'http://OLD_IP:9000', 'http://YOUR_EC2_PUBLIC_IP:9000') 
WHERE url LIKE '%OLD_IP%';
```
Note: user_info, blog_graph_info, graph_info tables also need corresponding IP address updates.