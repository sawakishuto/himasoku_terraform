# 🚀 HimaSoku CD セットアップガイド

## 📋 セットアップ手順

### 1. **リモートステートの設定**

```bash
# Cloud Storageバケットを作成
./setup-remote-state.sh

# リモートステートに移行
terraform init -migrate-state
```

### 2. **GCP サービスアカウントの作成**

```bash
# Terraform用サービスアカウント作成
gcloud iam service-accounts create terraform-cd \
    --display-name="Terraform CD Service Account"

# 必要な権限を付与
gcloud projects add-iam-policy-binding himasoku \
    --member="serviceAccount:terraform-cd@himasoku.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding himasoku \
    --member="serviceAccount:terraform-cd@himasoku.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# サービスアカウントキーを作成
gcloud iam service-accounts keys create terraform-cd-key.json \
    --iam-account=terraform-cd@himasoku.iam.gserviceaccount.com
```

### 3. **GitHub Secrets の設定**

GitHub リポジトリの Settings > Secrets and variables > Actions で以下を設定：

| Secret 名     | 値                           | 説明           |
| ------------- | ---------------------------- | -------------- |
| `GCP_SA_KEY`  | terraform-cd-key.json の内容 | GCP 認証用     |
| `DB_PASSWORD` | データベースパスワード       | 本番 DB 接続用 |

### 4. **GitHub Actions の有効化**

1. GitHub リポジトリで Actions タブを開く
2. ワークフローを有効化
3. `main`ブランチにプッシュしてテスト

## 🔄 デプロイフロー

### **Pull Request 時**

```
PR作成 → Terraform Plan実行 → 結果をPRにコメント
```

### **Main ブランチマージ時**

```
マージ → Terraform Apply → アプリケーションビルド → Cloud Runデプロイ
```

## 📁 ディレクトリ構造

```
himasoku_terraform/
├── .github/workflows/
│   ├── terraform.yml      # インフラ管理
│   └── deploy.yml         # アプリデプロイ
├── environments/
│   └── production.tfvars  # 本番環境設定
├── backend.tf             # リモートステート設定
├── main.tf               # インフラ定義
├── variables.tf          # 変数定義
├── outputs.tf            # 出力定義
└── terraform.tfvars.example  # 設定例
```

## 🔒 セキュリティ考慮事項

1. **機密情報の管理**

   - パスワードは GitHub Secrets で管理
   - サービスアカウントキーは適切に保護

2. **権限の最小化**

   - 必要最小限の権限のみ付与
   - 定期的な権限レビュー

3. **承認フロー**
   - 本番デプロイには承認を必要とする設定も可能

## 🚨 トラブルシューティング

### よくある問題と解決策

1. **権限エラー**

   ```bash
   # サービスアカウントの権限を確認
   gcloud projects get-iam-policy himasoku
   ```

2. **ステートファイルの競合**

   ```bash
   # ステートロックを解除
   terraform force-unlock LOCK_ID
   ```

3. **デプロイ失敗**
   - GitHub Actions のログを確認
   - GCP コンソールでリソース状態を確認

## 📈 次のステップ

1. **モニタリング追加**

   - Cloud Monitoring 設定
   - アラート設定

2. **テスト自動化**

   - 単体テスト
   - 統合テスト

3. **ロールバック機能**
   - 自動ロールバック
   - 手動ロールバック手順
