# ========================================
# 스토리지 모듈
# ========================================
module "storage" {
  source = "../../modules/storage"

  project_id       = var.project_id
  default_location = var.storage_location
  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  # 버킷 정의
  buckets = merge(
    var.create_storage_buckets ? tomap({
      static_assets = {
        name                        = "${var.project_id}-${var.environment}-static-assets"
        storage_class               = "STANDARD"
        uniform_bucket_level_access = true
        versioning_enabled          = true
        force_destroy               = false      # 운영 버킷은 강제 삭제를 사용하지 않습니다.
        public_access_prevention    = "enforced" # 공개 액세스를 차단합니다.

        # 365일이 지난 정적 파일은 Nearline 클래스로 이동합니다.
        lifecycle_rules = [
          {
            action = {
              type          = "SetStorageClass"
              storage_class = "NEARLINE"
            }
            condition = {
              age = 365
            }
          }
        ]

        # 정적 자산 제공을 위한 CORS 설정입니다.
        cors = length(var.allowed_cors_origins) > 0 ? [
          {
            origin          = var.allowed_cors_origins
            method          = ["GET", "HEAD"]
            response_header = ["Content-Type"]
            max_age_seconds = 3600
          }
        ] : []
      }
    }) : tomap({}),
    var.create_storage_buckets ? tomap({
      backups = {
        name                        = "${var.project_id}-${var.environment}-backups"
        storage_class               = "NEARLINE"
        uniform_bucket_level_access = true
        versioning_enabled          = true
        force_destroy               = false
        public_access_prevention    = "enforced"

        # 오래된 백업은 저장 등급을 낮추고 최종적으로 삭제합니다.
        lifecycle_rules = [
          {
            action = {
              type          = "SetStorageClass"
              storage_class = "COLDLINE"
            }
            condition = {
              age = 90
            }
          },
          {
            action = {
              type = "Delete"
            }
            condition = {
              age                = 365
              num_newer_versions = 10
            }
          }
        ]
      }
    }) : tomap({}),
    var.create_storage_buckets ? tomap({
      logs = {
        name                        = "${var.project_id}-${var.environment}-logs"
        storage_class               = "STANDARD"
        uniform_bucket_level_access = true
        versioning_enabled          = false
        force_destroy               = false
        public_access_prevention    = "enforced"

        # 로그 버킷은 30일 이후 자동 삭제합니다.
        lifecycle_rules = [
          {
            action = {
              type = "Delete"
            }
            condition = {
              age = 30
            }
          }
        ]
      }
    }) : tomap({})
  )
}
