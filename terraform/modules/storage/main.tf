# ========================================
# Cloud Storage 버킷 리소스
# ========================================
resource "google_storage_bucket" "buckets" {
  for_each = var.buckets

  name          = each.value.name
  location      = coalesce(lookup(each.value, "location", null), var.default_location)
  storage_class = coalesce(lookup(each.value, "storage_class", null), var.default_storage_class)

  # 버킷이 생성될 프로젝트입니다.
  project = var.project_id

  # 기본 태그와 버킷별 태그를 GCP 레이블에 반영합니다.
  labels = merge(
    {
      for k, v in var.common_tags : lower(k) => lower(v)
    },
    {
      for k, v in coalesce(lookup(each.value, "common_tags", null), {}) : lower(k) => lower(v)
    }
  )

  # 균일한 버킷 수준 액세스 설정입니다.
  uniform_bucket_level_access = coalesce(lookup(each.value, "uniform_bucket_level_access", null), true)

  # 버전 관리가 활성화된 버킷만 versioning 블록을 추가합니다.
  dynamic "versioning" {
    for_each = coalesce(lookup(each.value, "versioning_enabled", null), false) ? [1] : []
    content {
      enabled = true
    }
  }

  # 생명 주기 규칙 정의입니다.
  dynamic "lifecycle_rule" {
    for_each = coalesce(lookup(each.value, "lifecycle_rules", null), [])
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }

      condition {
        age                   = lookup(lifecycle_rule.value.condition, "age", null)
        created_before        = lookup(lifecycle_rule.value.condition, "created_before", null)
        num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
        with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        matches_prefix        = lookup(lifecycle_rule.value.condition, "matches_prefix", null)
        matches_suffix        = lookup(lifecycle_rule.value.condition, "matches_suffix", null)
      }
    }
  }

  # CORS가 정의된 경우에만 설정합니다.
  dynamic "cors" {
    for_each = coalesce(lookup(each.value, "cors", null), [])
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = lookup(cors.value, "response_header", [])
      max_age_seconds = lookup(cors.value, "max_age_seconds", 3600)
    }
  }

  # 정적 웹사이트 호스팅이 필요한 경우에만 설정합니다.
  dynamic "website" {
    for_each = lookup(each.value, "website", null) != null ? [each.value.website] : []
    content {
      main_page_suffix = lookup(website.value, "main_page_suffix", "index.html")
      not_found_page   = lookup(website.value, "not_found_page", "404.html")
    }
  }

  # KMS 키가 전달된 경우에만 기본 암호화를 설정합니다.
  dynamic "encryption" {
    for_each = lookup(each.value, "encryption_key", null) != null ? [1] : []
    content {
      default_kms_key_name = each.value.encryption_key
    }
  }

  # 액세스 로그 저장 버킷이 정의된 경우에만 설정합니다.
  dynamic "logging" {
    for_each = lookup(each.value, "logging_config", null) != null ? [each.value.logging_config] : []
    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = lookup(logging.value, "log_object_prefix", "")
    }
  }

  # 보존 정책이 정의된 경우에만 설정합니다.
  dynamic "retention_policy" {
    for_each = lookup(each.value, "retention_policy", null) != null ? [each.value.retention_policy] : []
    content {
      retention_period = retention_policy.value.retention_period
      is_locked        = lookup(retention_policy.value, "is_locked", false)
    }
  }

  # 공개 액세스 방지 정책입니다.
  public_access_prevention = coalesce(lookup(each.value, "public_access_prevention", null), "inherited")

  # force_destroy는 버킷 내 객체까지 함께 삭제하므로 운영 환경에서는 주의가 필요합니다.
  force_destroy = coalesce(lookup(each.value, "force_destroy", null), false)
}

# ========================================
# 버킷 IAM 리소스
# ========================================
resource "google_storage_bucket_iam_binding" "bucket_iam" {
  for_each = var.bucket_iam_bindings

  bucket  = google_storage_bucket.buckets[each.value.bucket_key].name
  role    = each.value.role
  members = each.value.members
}

resource "google_storage_bucket_iam_member" "bucket_iam_member" {
  for_each = var.bucket_iam_members

  bucket = google_storage_bucket.buckets[each.value.bucket_key].name
  role   = each.value.role
  member = each.value.member
}

# ========================================
# 버킷 객체 리소스
# ========================================
resource "google_storage_bucket_object" "objects" {
  for_each = var.bucket_objects

  name         = each.value.name
  bucket       = google_storage_bucket.buckets[each.value.bucket_key].name
  source       = lookup(each.value, "source", null)
  content      = lookup(each.value, "content", null)
  content_type = lookup(each.value, "content_type", null)

  # 사용자 정의 메타데이터입니다.
  metadata = lookup(each.value, "metadata", {})

  # 캐시 제어 헤더입니다.
  cache_control = lookup(each.value, "cache_control", null)

  # Content-Disposition 헤더입니다.
  content_disposition = lookup(each.value, "content_disposition", null)

  # Content-Encoding 헤더입니다.
  content_encoding = lookup(each.value, "content_encoding", null)

  # Content-Language 헤더입니다.
  content_language = lookup(each.value, "content_language", null)
}

# ========================================
# 버킷 알림 리소스
# ========================================
resource "google_storage_notification" "notifications" {
  for_each = var.bucket_notifications

  bucket         = google_storage_bucket.buckets[each.value.bucket_key].name
  topic          = each.value.topic
  payload_format = lookup(each.value, "payload_format", "JSON_API_V1")

  # 알림을 받을 이벤트 타입입니다.
  event_types = lookup(each.value, "event_types", ["OBJECT_FINALIZE"])

  # 커스텀 속성입니다.
  custom_attributes = lookup(each.value, "custom_attributes", {})

  # 특정 접두사를 가진 객체만 필터링합니다.
  object_name_prefix = lookup(each.value, "object_name_prefix", null)
}
