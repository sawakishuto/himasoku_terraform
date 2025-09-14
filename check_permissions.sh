#!/bin/bash

# GCP 権限確認スクリプト
# 既存プロジェクトのインポート前に実行してください

PROJECT_ID="himasoku"

echo "=== GCP 権限確認スクリプト ==="
echo "プロジェクト ID: $PROJECT_ID"
echo ""

# 現在の認証状態
echo "=== 認証状態 ==="
echo "アクティブアカウント:"
gcloud auth list --filter=status:ACTIVE --format="value(account)"
echo ""

echo "設定されたプロジェクト:"
gcloud config get-value project
echo ""

# 各サービスの権限確認
echo "=== 権限確認 ==="

# Compute Engine 権限
echo -n "Compute Engine 権限: "
if gcloud compute networks list --project=$PROJECT_ID --format="value(name)" >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ NG - Compute Engine Admin 権限が必要です"
fi

# Cloud SQL 権限
echo -n "Cloud SQL 権限: "
if gcloud sql instances list --project=$PROJECT_ID --format="value(name)" >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ NG - Cloud SQL Admin 権限が必要です"
fi

# Cloud Run 権限
echo -n "Cloud Run 権限: "
if gcloud run services list --project=$PROJECT_ID --platform=managed --format="value(metadata.name)" >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ NG - Cloud Run Admin 権限が必要です"
fi

# Service Usage 権限
echo -n "Service Usage 権限: "
if gcloud services list --project=$PROJECT_ID --format="value(name)" --limit=1 >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ NG - Service Usage Admin 権限が必要です"
fi

# VPC Access 権限
echo -n "VPC Access 権限: "
if gcloud compute networks vpc-access connectors list --region=asia-northeast1 --project=$PROJECT_ID >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ NG - VPC Access Admin 権限が必要です"
fi

echo ""
echo "=== 既存リソース確認 ==="

# VPC ネットワーク
echo "VPC ネットワーク:"
gcloud compute networks list --project=$PROJECT_ID --format="table(name,mode,IPv4Range)" 2>/dev/null || echo "  アクセスできません"

echo ""

# Cloud SQL インスタンス
echo "Cloud SQL インスタンス:"
gcloud sql instances list --project=$PROJECT_ID --format="table(name,database_version,region,gceZone,status)" 2>/dev/null || echo "  アクセスできません"

echo ""

# Cloud Run サービス
echo "Cloud Run サービス:"
gcloud run services list --project=$PROJECT_ID --platform=managed --format="table(metadata.name,status.url,status.latestReadyRevisionName)" 2>/dev/null || echo "  アクセスできません"

echo ""

# VPC コネクタ
echo "VPC コネクタ:"
gcloud compute networks vpc-access connectors list --region=asia-northeast1 --project=$PROJECT_ID --format="table(name,network,ipCidrRange,state)" 2>/dev/null || echo "  アクセスできません"

echo ""
echo "=== 推奨される権限付与コマンド ==="
echo "現在のアカウント: $(gcloud config get-value account)"
echo ""
echo "# プロジェクトオーナー権限を付与（推奨）"
echo "gcloud projects add-iam-policy-binding $PROJECT_ID \\"
echo "    --member=\"user:$(gcloud config get-value account)\" \\"
echo "    --role=\"roles/owner\""
echo ""
echo "# または個別権限を付与"
echo "gcloud projects add-iam-policy-binding $PROJECT_ID --member=\"user:$(gcloud config get-value account)\" --role=\"roles/compute.admin\""
echo "gcloud projects add-iam-policy-binding $PROJECT_ID --member=\"user:$(gcloud config get-value account)\" --role=\"roles/cloudsql.admin\""
echo "gcloud projects add-iam-policy-binding $PROJECT_ID --member=\"user:$(gcloud config get-value account)\" --role=\"roles/run.admin\""
echo "gcloud projects add-iam-policy-binding $PROJECT_ID --member=\"user:$(gcloud config get-value account)\" --role=\"roles/serviceusage.serviceUsageAdmin\""
echo "gcloud projects add-iam-policy-binding $PROJECT_ID --member=\"user:$(gcloud config get-value account)\" --role=\"roles/vpcaccess.admin\""
