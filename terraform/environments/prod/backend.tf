# ========================================
# GCS 백엔드 설정
# ========================================
terraform {
  # State 파일을 저장할 버킷
  backend "gcs" {
    bucket = "pinhouse-prod-state-bucket"
    prefix = "terraform/prod/state"
  }
}
