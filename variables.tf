variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "himasoku"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast1"
}

variable "container_image" {
  description = "Container image for Cloud Run"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "himasoku_db"
}

variable "database_user" {
  description = "Database user name"
  type        = string
  default     = "himasoku_user"
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
