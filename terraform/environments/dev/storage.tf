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
  buckets = merge(

    # 기본 버킷 추가
    var.create_storage_buckets ? tomap({
      static_assets = {
        name                        = "${var.project}-${var.environment}"
        storage_class               = "STANDARD"
        uniform_bucket_level_access = true
        versioning_enabled          = true
        force_destroy               = true # 개발 환경에서는 빠른 정리를 위해 강제 삭제를 허용합니다.
        public_access_prevention    = "enforced"

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

    # 모니터링 버킷 추가
    var.create_monitoring_buckets ? tomap({
      loki = {
        name                        = "${var.project}-${var.environment}-${var.monitoring_loki}"
        storage_class               = "STANDARD"
        uniform_bucket_level_access = true
        versioning_enabled          = true
        force_destroy               = true # 개발 환경에서는 빠른 정리를 위해 강제 삭제를 허용합니다.
        public_access_prevention    = "enforced"
        cors                        = []
      }
      tempo = {
        name                        = "${var.project}-${var.environment}-${var.monitoring_tempo}"
        storage_class               = "STANDARD"
        uniform_bucket_level_access = true
        versioning_enabled          = true
        force_destroy               = true # 개발 환경에서는 빠른 정리를 위해 강제 삭제를 허용합니다.
        public_access_prevention    = "enforced"
        cors                        = []
      }
    }) : tomap({}),
  )
}
