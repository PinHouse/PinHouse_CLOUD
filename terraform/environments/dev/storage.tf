# ========================================
# 스토리지 모듈
# ========================================
module "storage" {
  source = "../../modules/storage"

  project_id       = var.project_id
  default_location = var.storage_location

  # 태그
  common_tags = merge(var.common_tags, {
    Service = "Storage"
  })

  # 버킷 정의
  buckets = var.create_storage_buckets ? tomap({
    static_assets = {
      name                        = "${var.project_id}-${var.environment}-static-assets"
      storage_class               = "STANDARD"
      uniform_bucket_level_access = true
      versioning_enabled          = false
      force_destroy               = true # 개발 환경에서는 빠른 정리를 위해 강제 삭제를 허용합니다.

      # 90일이 지난 정적 파일은 자동 삭제합니다.
      lifecycle_rules = [
        {
          action = {
            type = "Delete"
          }
          condition = {
            age = 90
          }
        }
      ]

      # 정적 자산 조회를 위한 CORS 설정입니다.
      cors = [
        {
          origin          = ["*"]
          method          = ["GET", "HEAD"]
          response_header = ["*"]
          max_age_seconds = 3600
        }
      ]
    }

    backups = {
      name                        = "${var.project_id}-${var.environment}-backups"
      storage_class               = "NEARLINE"
      uniform_bucket_level_access = true
      versioning_enabled          = true
      force_destroy               = true

      # 최신 버전 일부를 제외한 오래된 백업은 자동 삭제합니다.
      lifecycle_rules = [
        {
          action = {
            type = "Delete"
          }
          condition = {
            age                = 30
            num_newer_versions = 3
          }
        }
      ]
    }
  }) : tomap({})
}
