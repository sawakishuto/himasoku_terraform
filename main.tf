terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network (既存のdefaultネットワークを使用)
resource "google_compute_network" "vpc" {
  name                    = "default"
  auto_create_subnetworks = true
  description             = "Default network for the project"
}

# VPC Connector for Cloud Run to access Cloud SQL - 既存のコネクタ
resource "google_vpc_access_connector" "connector" {
  name            = "himasoku-vpc-connector"
  ip_cidr_range   = "10.8.0.0/28"
  network         = google_compute_network.vpc.name
  region          = var.region
  min_throughput  = 300  # 既存の設定に合わせる
  max_throughput  = 400  # 既存の設定に合わせる
  min_instances   = 3    # 既存の設定に合わせる
  max_instances   = 4    # 既存の設定に合わせる
}

# Cloud SQL Instance (PostgreSQL) - 既存のインスタンス
resource "google_sql_database_instance" "postgres" {
  name             = "himasoku-db"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro"  # 最も安いプラン
    
    disk_type    = "PD_SSD"  # 既存の設定に合わせる
    disk_size    = 10
    disk_autoresize = true
    disk_autoresize_limit = 0  # 既存の設定に合わせる

    backup_configuration {
      enabled    = false  # 既存の設定に合わせる
      start_time = "13:00"  # 既存の設定に合わせる
    }

    ip_configuration {
      ipv4_enabled    = false  # 既存の設定に合わせる（プライベートIPのみ）
      private_network = google_compute_network.vpc.id
      require_ssl     = false  # 既存の設定に合わせる
      
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = true  # 既存の設定に合わせる
}

# Cloud Run Service - 既存のサービス
resource "google_cloud_run_v2_service" "app" {
  name     = "himasoku"
  location = var.region

  template {
    scaling {
      min_instance_count = 0  # リクエストベース（最小0）
      max_instance_count = 3  # 既存の設定に合わせる
    }

    containers {
      image = var.container_image
      name  = "web-1"  # 既存の設定に合わせる

      ports {
        container_port = 8080
      }

      # 既存の環境変数を保持
      env {
        name  = "RAILS_ENV"
        value = "production"
      }

      env {
        name  = "RAILS_LOG_LEVEL"
        value = "info"
      }

      env {
        name  = "REDIS_URL"
        value = "rediss://red-d2hm9u0gjchc73a833v0:INWd9L2UrkNlZDQItvpyjLBEI5pS9yYa@oregon-keyvalue.render.com:6379"
      }

      env {
        name  = "RAILS_LOG_TO_STDOUT"
        value = "true"
      }

      env {
        name  = "APNS_ENVIRONMENT"
        value = "production"
      }

      # 既存のSecret Manager参照を保持
      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = "RAILS_MASTER_KEY"
            version = "latest"
          }
        }
      }

      env {
        name = "DB_HOST"
        value_source {
          secret_key_ref {
            secret  = "DB_HOST"
            version = "latest"
          }
        }
      }

      env {
        name = "POSTGRES_DB"
        value_source {
          secret_key_ref {
            secret  = "POSTGRES_DB"
            version = "latest"
          }
        }
      }

      env {
        name = "POSTGRES_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = "POSTGRES_PASSWORD"
            version = "latest"
          }
        }
      }

      env {
        name = "POSTGRES_USER"
        value_source {
          secret_key_ref {
            secret  = "POSTGRES_USER"
            version = "latest"
          }
        }
      }

      env {
        name = "RAILS_SECRET_KEY_BASE"
        value_source {
          secret_key_ref {
            secret  = "rails_secret_key_base"
            version = "latest"
          }
        }
      }

      env {
        name = "APNS_KEY_ID"
        value_source {
          secret_key_ref {
            secret  = "APNS_KEY_ID"
            version = "latest"
          }
        }
      }

      env {
        name = "APNS_TEAM_ID"
        value_source {
          secret_key_ref {
            secret  = "APNS_TEAM_ID"
            version = "latest"
          }
        }
      }

      env {
        name = "APNS_BUNDLE_ID"
        value_source {
          secret_key_ref {
            secret  = "APNS_BUNDLE_ID"
            version = "latest"
          }
        }
      }

      env {
        name = "APNS_AUTH_KEY_CONTENT"
        value_source {
          secret_key_ref {
            secret  = "apns-key-file"
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1000m"  # 既存の設定に合わせる
          memory = "512Mi"
        }
        cpu_idle = true  # 既存の設定に合わせる
      }

      # 既存のCloud SQLボリュームマウントを保持
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    # 既存のCloud SQLボリューム設定を保持
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = ["himasoku:asia-northeast1:himasoku-db"]
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"  # 既存の設定に合わせる
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# Secret Manager for database password (既存のシークレットを使用するためコメントアウト)
# resource "google_secret_manager_secret" "db_password" {
#   secret_id = "himasoku-db-password"
#
#   replication {
#     auto {}
#   }
# }

# resource "google_secret_manager_secret_version" "db_password" {
#   secret      = google_secret_manager_secret.db_password.id
#   secret_data = var.database_password
# }

# Cloud Run IAM
resource "google_cloud_run_service_iam_binding" "invoker" {
  location = google_cloud_run_v2_service.app.location
  service  = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com"
  ])

  service = each.value

  disable_dependent_services = false  # 既存プロジェクトでは false に設定
}
