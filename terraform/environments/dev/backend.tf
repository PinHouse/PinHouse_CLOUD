# ========================================
# Terraform Backend 설정
# ========================================
terraform {
  backend "gcs" {
    bucket = "pinhouse-dev-terraform-state-bucket"
    prefix = "terraform/dev/state"
  }
}
