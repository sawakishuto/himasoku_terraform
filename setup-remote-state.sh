#!/bin/bash

# Terraformリモートステート用のCloud Storageバケット作成スクリプト

set -e

PROJECT_ID="himasoku"
BUCKET_NAME="himasoku-terraform-state"
REGION="asia-northeast1"

echo "=== Terraformリモートステートの設定 ==="
echo "プロジェクト: $PROJECT_ID"
echo "バケット: $BUCKET_NAME"
echo "リージョン: $REGION"
echo ""

# 現在のプロジェクト設定を確認
echo "現在のGCPプロジェクト設定を確認中..."
gcloud config set project $PROJECT_ID

# Cloud Storage APIの有効化
echo "Cloud Storage APIを有効化中..."
gcloud services enable storage.googleapis.com

# バケットの存在確認
if gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
    echo "バケット gs://$BUCKET_NAME は既に存在します"
else
    echo "バケット gs://$BUCKET_NAME を作成中..."
    gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$BUCKET_NAME
    
    # バケットのバージョニングを有効化（状態ファイルの履歴管理）
    echo "バケットのバージョニングを有効化中..."
    gsutil versioning set on gs://$BUCKET_NAME
    
    # バケットの暗号化設定
    echo "バケットの暗号化を設定中..."
    gsutil encryption set -k projects/$PROJECT_ID/locations/global/keyRings/terraform-state/cryptoKeys/terraform-state-key gs://$BUCKET_NAME || echo "暗号化キーが存在しない場合はデフォルト暗号化を使用"
fi

echo ""
echo "=== 次のステップ ==="
echo "1. backend.tfファイルが作成されました"
echo "2. 以下のコマンドでリモートステートに移行してください："
echo ""
echo "   terraform init -migrate-state"
echo ""
echo "3. 移行後、ローカルのterraform.tfstateファイルを削除できます"
echo ""
echo "バケット情報:"
echo "  名前: gs://$BUCKET_NAME"
echo "  リージョン: $REGION"
echo "  バージョニング: 有効"
