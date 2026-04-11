# ========================================
# Terraform Backend 설정
# ========================================
terraform {
  backend "gcs" {
    bucket = "pinhouse-dev-state-bucket"
    prefix = "terraform/dev/state"
  }
}
