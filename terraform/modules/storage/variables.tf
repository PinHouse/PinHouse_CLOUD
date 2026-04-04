# ========================================
# 스토리지 기본 변수
# ========================================
variable "project_id" {
  description = "버킷을 생성할 GCP 프로젝트 ID입니다."
  type        = string
}

variable "default_location" {
  description = "버킷 기본 생성 위치입니다. 리전 또는 멀티 리전을 사용할 수 있습니다."
  type        = string
  default     = "ASIA-NORTHEAST3"
}

variable "default_storage_class" {
  description = "버킷 기본 스토리지 클래스입니다. STANDARD, NEARLINE, COLDLINE, ARCHIVE 중 하나를 사용합니다."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.default_storage_class)
    error_message = "default_storage_class는 STANDARD, NEARLINE, COLDLINE, ARCHIVE 중 하나여야 합니다."
  }
}

variable "common_tags" {
  description = "모든 버킷에 공통 적용할 태그입니다."
  type        = map(string)
  default     = {}
}

# ========================================
# 버킷 정의 변수
# ========================================
variable "buckets" {
  description = "생성할 버킷 정의 목록입니다."
  type = map(object({
    name                        = string
    location                    = optional(string)
    storage_class               = optional(string)
    common_tags                 = optional(map(string))
    uniform_bucket_level_access = optional(bool)
    versioning_enabled          = optional(bool)
    force_destroy               = optional(bool)
    public_access_prevention    = optional(string)
    encryption_key              = optional(string)
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                   = optional(number)
        created_before        = optional(string)
        num_newer_versions    = optional(number)
        with_state            = optional(string)
        matches_storage_class = optional(list(string))
        matches_prefix        = optional(list(string))
        matches_suffix        = optional(list(string))
      })
    })))
    cors = optional(list(object({
      origin          = list(string)
      method          = list(string)
      response_header = optional(list(string))
      max_age_seconds = optional(number)
    })))
    website = optional(object({
      main_page_suffix = optional(string)
      not_found_page   = optional(string)
    }))
    logging_config = optional(object({
      log_bucket        = string
      log_object_prefix = optional(string)
    }))
    retention_policy = optional(object({
      retention_period = number
      is_locked        = optional(bool)
    }))
  }))
  default = {}
}

# ========================================
# IAM 및 객체 변수
# ========================================
variable "bucket_iam_bindings" {
  description = "버킷 IAM 바인딩 정의 목록입니다."
  type = map(object({
    bucket_key = string
    role       = string
    members    = list(string)
  }))
  default = {}
}

variable "bucket_iam_members" {
  description = "버킷 IAM 멤버 정의 목록입니다."
  type = map(object({
    bucket_key = string
    role       = string
    member     = string
  }))
  default = {}
}

variable "bucket_objects" {
  description = "버킷에 업로드할 객체 정의 목록입니다."
  type = map(object({
    bucket_key          = string
    name                = string
    source              = optional(string)
    content             = optional(string)
    content_type        = optional(string)
    metadata            = optional(map(string))
    cache_control       = optional(string)
    content_disposition = optional(string)
    content_encoding    = optional(string)
    content_language    = optional(string)
  }))
  default = {}
}

# ========================================
# 버킷 알림 변수
# ========================================
variable "bucket_notifications" {
  description = "Cloud Pub/Sub 기반 버킷 알림 정의 목록입니다."
  type = map(object({
    bucket_key         = string
    topic              = string
    payload_format     = optional(string)
    event_types        = optional(list(string))
    custom_attributes  = optional(map(string))
    object_name_prefix = optional(string)
  }))
  default = {}
}
