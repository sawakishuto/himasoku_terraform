#!/bin/bash

# 既存 GCP リソースを Terraform にインポートするスクリプト
# 使用前に以下の変数を実際の値に置き換えてください

set -e

# 設定変数（実際の値に置き換えてください）
PROJECT_ID="himasoku"
REGION="asia-northeast1"
PROJECT_NAME="HimaSoku"

# 既存リソース名（実際の名前に置き換えてください）
VPC_NAME="default"
SUBNET_NAME="default"
SQL_INSTANCE_NAME="himasoku-db"
CLOUD_RUN_SERVICE="himasoku"
VPC_CONNECTOR="himasoku-vpc-connector"

echo "=== 既存 GCP リソースのインポートを開始します ==="
echo "プロジェクト ID: $PROJECT_ID"
echo "リージョン: $REGION"
echo ""

# 現在の認証状態を確認
echo "認証状態を確認中..."
gcloud auth list --filter=status:ACTIVE --format="value(account)"

# プロジェクトを設定
echo "プロジェクトを設定中..."
gcloud config set project $PROJECT_ID

echo ""
echo "=== 既存リソースの確認 ==="

# 既存リソースの存在確認
echo "VPC ネットワークを確認中..."
gcloud compute networks describe $VPC_NAME --format="value(name)" 2>/dev/null || echo "VPC '$VPC_NAME' が見つかりません"

echo "Cloud SQL インスタンスを確認中..."
gcloud sql instances describe $SQL_INSTANCE_NAME --format="value(name)" 2>/dev/null || echo "SQL インスタンス '$SQL_INSTANCE_NAME' が見つかりません"

echo "Cloud Run サービスを確認中..."
gcloud run services describe $CLOUD_RUN_SERVICE --region=$REGION --format="value(metadata.name)" 2>/dev/null || echo "Cloud Run サービス '$CLOUD_RUN_SERVICE' が見つかりません"

echo ""
read -p "上記のリソースが存在することを確認しましたか？続行しますか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "インポートを中止しました。"
    exit 1
fi

echo ""
echo "=== Terraform の初期化 ==="
terraform init

echo ""
echo "=== リソースのインポート開始 ==="

# VPC ネットワーク
echo "VPC ネットワークをインポート中..."
terraform import google_compute_network.vpc projects/$PROJECT_ID/global/networks/$VPC_NAME || echo "VPC のインポートに失敗しました（既にインポート済みの可能性があります）"

# サブネット
echo "サブネットをインポート中..."
terraform import google_compute_subnetwork.subnet projects/$PROJECT_ID/regions/$REGION/subnetworks/$SUBNET_NAME || echo "サブネットのインポートに失敗しました"

# VPC コネクタ（存在する場合）
echo "VPC コネクタをインポート中..."
terraform import google_vpc_access_connector.connector projects/$PROJECT_ID/locations/$REGION/connectors/$VPC_CONNECTOR || echo "VPC コネクタのインポートに失敗しました"

# Cloud SQL インスタンス
echo "Cloud SQL インスタンスをインポート中..."
terraform import google_sql_database_instance.postgres $PROJECT_ID:$SQL_INSTANCE_NAME || echo "SQL インスタンスのインポートに失敗しました"

# データベース（存在する場合）
echo "データベースをインポート中..."
DB_NAME=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.address=="google_sql_database_instance.postgres") | .values.database_version' 2>/dev/null || echo "himasoku_db")
terraform import google_sql_database.database $PROJECT_ID/$SQL_INSTANCE_NAME/$DB_NAME || echo "データベースのインポートに失敗しました"

# Cloud Run サービス
echo "Cloud Run サービスをインポート中..."
terraform import google_cloud_run_v2_service.app projects/$PROJECT_ID/locations/$REGION/services/$CLOUD_RUN_SERVICE || echo "Cloud Run サービスのインポートに失敗しました"

# プロジェクト API の有効化状態をインポート
echo "プロジェクト API をインポート中..."
APIS=("run.googleapis.com" "sql-component.googleapis.com" "sqladmin.googleapis.com" "vpcaccess.googleapis.com" "servicenetworking.googleapis.com" "secretmanager.googleapis.com")

for api in "${APIS[@]}"; do
    echo "API $api をインポート中..."
    terraform import "google_project_service.apis[\"$api\"]" $PROJECT_ID/$api || echo "API $api のインポートに失敗しました"
done

echo ""
echo "=== インポート完了 ==="
echo "次のステップ:"
echo "1. terraform plan を実行して差分を確認してください"
echo "2. 必要に応じて terraform.tfvars や設定ファイルを調整してください"
echo "3. terraform apply で設定を同期してください"
echo ""
echo "差分確認コマンド:"
echo "terraform plan"
