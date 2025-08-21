# 🏠 賃貸管理システム - AWS EC2 完全デプロイガイド

**日本語版** | [中文版](./readme_cn.md) | [English Version](./readme_en.md)

## 🔍 プロジェクト概要 - 機能紹介と技術詳細
[lease-system-backend](https://github.com/yukoto0718/lease-system-backend.git)

## プロジェクトの背景

**賃貸管理システム**は、**Spring Boot + Vue.js + Docker**技術スタックで開発されたマイクロサービスアーキテクチャに基づく完全な賃貸管理プラットフォームです。システムはユーザー向けH5アプリケーションと管理者向けバックエンドで構成され、物件管理、ユーザー管理、内見予約、契約管理などの完全なビジネスプロセスをサポートします。

### 技術スタック構成

- **フロントエンド**: Vue.js H5ユーザー端 + Vue.js管理画面
- **バックエンド**: Spring Bootマイクロサービスアーキテクチャ
- **データベース**: MySQL 8.0 + Redisキャッシュ
- **ファイルストレージ**: MinIOオブジェクトストレージ
- **Webサーバー**: Nginxリバースプロキシ
- **コンテナ化**: Docker + Docker Compose
- **CI/CD**: GitHub Actions自動デプロイ

---

## 体験用URL

> 本デモシステムは**AWS EC2 (t2.micro)**無料枠インスタンスにデプロイされており、技術展示と学習交流目的のみで使用されています。

### フロントエンドアクセス
**モバイル端**: http://57.183.57.12

ユーザー①：`ユーザー名 13112345678 / パスワード 123456`
ユーザー②：`ユーザー名 13212345678 / パスワード 123456`
ユーザー③：`ユーザー名 13312345678 / パスワード 123456`

### 管理画面
**管理システム**: http://57.183.57.12:8888

`ユーザー名：user / パスワード：123456`

### MINIO
**MinIOコンソール**: http://57.183.57.12:9001

`ユーザー名：minioadmin / パスワード：minioadmin`

## デプロイ手順

### 1. AWS EC2インスタンスの作成

**インスタンス設定要件**

> インスタンス名: lease-production-server
> AMI: Amazon Linux 2023 AMI (Free tier eligible)
> インスタンスタイプ: t2.micro (Free tier eligible)
> セキュリティグループ作成: lease-server-sg
> ストレージ: 30GB (Free tier)
> 固定IP: Allocate Elastic IP addressを有効化

| タイプ | プロトコル | ポート範囲 | ソース | 説明 |
|------|----------|------------|---------|-------------|
| SSH | TCP | 22 | My IP | SSHアクセス |
| HTTP | TCP | 80 | 0.0.0.0/0 | H5フロントエンド |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Admin API |
| Custom TCP | TCP | 8081 | 0.0.0.0/0 | App API |
| Custom TCP | TCP | 8888 | 0.0.0.0/0 | Admin フロントエンド |
| Custom TCP | TCP | 9001 | 0.0.0.0/0 | MinIOコンソール |
| Custom TCP | TCP | 8082 | 0.0.0.0/0 | Adminer |
| Custom TCP | TCP | 9000 | 0.0.0.0/0 | MinIO API |

## ステップ2：EC2接続と基本環境インストール

**2.1 SSH接続**
```powershell
# Windows PowerShell
cd C:\aws-keys\
ssh -i lease-server-key.pem ec2-user@あなたのEC2パブリックIP
2.2 必要なソフトウェアのインストール
bash# システム更新
sudo yum update -y
```

Dockerインストール
```
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
```

Docker Composeインストール
```
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Gitインストール
```
sudo yum install git -y
```

Dockerグループ権限を適用するため退出
```
exit
```

## ステップ3：Swapスペース設定（重要なステップ）
なぜSwapが必要？
t2.microは1GBメモリのみで、7つのDockerコンテナを実行するとメモリ制限を超え、システムがフリーズします。
**3.1 再接続とSwap設定**
```bash
# 再接続
ssh -i lease-server-key.pem ec2-user@あなたのEC2パブリックIP
```

2GB Swapファイル作成
```
sudo dd if=/dev/zero of=/swapfile bs=1024 count=2097152
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Swapが有効か確認
```
free -h
起動時自動マウント設定
echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
成功指標：
Mem:   949Mi    192Mi     69Mi   0.0Ki   686Mi   608Mi
Swap:  2.0Gi       0B    2.0Gi
```

## ステップ4：プロジェクトクローンと設定
**4.1 プロジェクトコードクローン**
```bash
# GitHub Tokenを使用してクローン
git clone https://あなたのユーザー名:あなたのToken@github.com/あなたのユーザー名/lease-docker-project.git
cd lease-docker-project
```

**4.2 設定ファイル確認**
```bash
# IP設定確認
grep "MINIO_ENDPOINT" docker-compose.fixed.yml
```

環境変数確認
```
cat .env
```

データディレクトリ権限設定
```
sudo chown -R 999:999 data/mysql/
sudo chown -R 1000:1000 data/minio/
sudo chown -R 999:999 data/redis/
```

## ステップ5：段階的Dockerサービスデプロイ
なぜ段階的デプロイ？
7つのコンテナを同時起動してメモリ不足を避ける
MySQLが十分な時間でデータベースを初期化できるようにする
リソース使用状況の監視と問題の排除が容易

**5.1 コアサービス起動**
```bash
# MySQLとRedis起動
docker-compose -f docker-compose.fixed.yml up -d mysql redis
sleep 60
```

ステータス確認
```
docker ps
free -h
```

**5.2 データベース管理起動**
```bash
# Adminer起動
docker-compose -f docker-compose.fixed.yml up -d adminer
sleep 30
```
**5.3 バックエンドサービス起動**
```bash
# Spring Bootアプリケーション起動
docker-compose -f docker-compose.fixed.yml up -d web-admin web-app
sleep 30
```
**5.4 ストレージサービス起動**
```bash
# MinIO起動
docker-compose -f docker-compose.fixed.yml up -d minio
sleep 30
```
**5.5 フロントエンドサービス起動**
```bash# Nginx起動
docker-compose -f docker-compose.fixed.yml up -d nginx
sleep 30
```

# 最終ステータス確認
```
docker ps
free -h
```
成功指標：7つのコンテナすべてが実行中

## ステップ6：デプロイ検証
**6.1 サービスアクセス**
```
ユーザーページ: http://あなたのEC2パブリックIP
管理画面: http://あなたのEC2パブリックIP:8888
MinIOコンソール: http://あなたのEC2パブリックIP:9001
データベース管理: http://あなたのEC2パブリックIP:8082
```

**6.2 データベース管理ログイン**
```
Adminerログイン情報：
システム: MySQL
サーバー: mysql
ユーザー名: root
パスワード: Atguigu.123
データベース: lease
```

**6.3 画像表示修正**
画像が表示されない場合、Adminerで実行：
```sql
sqlUPDATE file_management 
SET url = REPLACE(url, 'http://旧IP:9000', 'http://あなたのEC2パブリックIP:9000') 
WHERE url LIKE '%旧IP%';
```
注意：user_info、blog_graph_info、graph_infoテーブルも対応するIPアドレスの変更が必要です。