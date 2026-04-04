# ========================================
# Google Provider 설정
# ========================================
provider "google" {
  project = var.project_id
  region  = var.region
}
