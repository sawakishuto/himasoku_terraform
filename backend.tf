# Terraform Backend Configuration
# リモートステート用のCloud Storage設定

terraform {
  backend "gcs" {
    bucket = "himasoku-terraform-state"
    prefix = "terraform/state"
  }
}
