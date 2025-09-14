# Himasoku Terraform Configuration

この Terraform プロジェクトは、Google Cloud Platform 上に Cloud Run と Cloud SQL（PostgreSQL）を使用したアプリケーションインフラストラクチャを構築します。

## 構成

- **Cloud Run**: リクエストベースのコンテナアプリケーション
- **Cloud SQL**: PostgreSQL（最安プラン: db-f1-micro）
- **VPC**: プライベートネットワーク
- **VPC Connector**: Cloud Run から Cloud SQL への接続
- **Secret Manager**: データベースパスワードの安全な管理

## セットアップ

1. **前提条件**

   - Google Cloud CLI がインストールされていること
   - Terraform がインストールされていること
   - GCP プロジェクトが作成されていること

2. **認証設定**

   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **変数ファイルの作成**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   `terraform.tfvars`を編集して、適切な値を設定してください。

4. **Terraform の初期化と実行**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 重要な設定

### Cloud SQL

- **プラン**: `db-f1-micro`（最安プラン）
- **ディスク**: 10GB HDD（自動拡張有効、最大 20GB）
- **ネットワーク**: プライベート IP のみ（セキュリティ向上）
- **SSL**: 必須

### Cloud Run

- **スケーリング**: 最小 0 インスタンス（リクエストベース）
- **リソース**: CPU 1 コア、メモリ 512Mi
- **ネットワーク**: VPC Connector を使用してプライベート通信

## 環境変数

Cloud Run アプリケーションには以下の環境変数が設定されます：

- `DB_HOST`: データベースのプライベート IP アドレス
- `DB_NAME`: データベース名
- `DB_USER`: データベースユーザー名
- `DB_PASSWORD`: データベースパスワード（Secret Manager から取得）

## セキュリティ

- データベースはプライベートネットワーク内でのみアクセス可能
- パスワードは Secret Manager で管理
- SSL 接続が必須
- Cloud Run は VPC Connector を通じてのみデータベースにアクセス

## コスト最適化

- Cloud SQL: 最安の db-f1-micro プランを使用
- Cloud Run: リクエストがない時は 0 インスタンスにスケールダウン
- ディスク: HDD を使用してコストを削減

## 注意事項

- 初回デプロイ時は、必要な API が有効化されるまで時間がかかる場合があります
- データベースの削除保護は無効になっています（`deletion_protection = false`）
- 本番環境では適切なバックアップとモニタリングの設定を追加してください
# himasoku_terraform
