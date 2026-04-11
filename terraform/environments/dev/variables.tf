# ========================================
# 프로젝트 기본 변수
# ========================================
variable "project_id" {
  description = "배포 대상 GCP 프로젝트 ID입니다."
  type        = string
  default     = "dev-pinhouse"
}

variable "project" {
  description = "현재 프로젝트 이름입니다."
  type        = string
  default     = "pinhouse"
}

variable "region" {
  description = "인프라를 배포할 GCP 리전입니다."
  type        = string
  default     = "asia-northeast3"
}

variable "environment" {
  description = "현재 Terraform 환경 이름입니다."
  type        = string
  default     = "dev"
}

# ========================================
# VPC 관련 변수
# ========================================
variable "vpc_name" {
  description = "생성할 VPC 네트워크 이름입니다."
  type        = string
  default     = "dev-vpc"
}

variable "ssh_source_ranges" {
  description = "직접 SSH 접근을 허용할 CIDR 목록입니다. 비워두면 IAP만 허용합니다."
  type        = list(string)
  default     = []
}

variable "enable_iap_ssh" {
  description = "IAP TCP 터널 기반 SSH 접근 허용 여부입니다."
  type        = bool
  default     = true
}

variable "iap_ssh_source_ranges" {
  description = "IAP TCP 터널이 인스턴스로 접근할 때 허용할 Google 관리 소스 CIDR 목록입니다."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "management_target_tags" {
  description = "SSH 및 IAP 관리 접근을 허용할 인스턴스 태그 목록입니다."
  type        = list(string)
  default     = ["web-server"]
}

variable "enable_nat" {
  description = "Cloud NAT 사용 여부입니다."
  type        = bool
  default     = true
}

# ========================================
# IAP 관련 변수
# ========================================
variable "iap_ssh_members" {
  description = "IAP 터널과 일반 OS Login 권한을 부여할 IAM 주체 목록입니다."
  type        = list(string)
  default     = []
}

variable "iap_ssh_admin_members" {
  description = "IAP 터널과 관리자 OS Login 권한을 부여할 IAM 주체 목록입니다."
  type        = list(string)
  default     = []
}

# ========================================
# Artifact Registry 관련 변수
# ========================================
variable "artifact_registry_location" {
  description = "Artifact Registry 저장소 기본 생성 위치입니다."
  type        = string
  default     = "asia-northeast3"
}

variable "artifact_registry_repositories" {
  description = "생성할 Artifact Registry 저장소 정의 목록입니다."
  type = map(object({
    repository_id  = string
    format         = string
    description    = optional(string)
    location       = optional(string)
    immutable_tags = optional(bool)
    common_tags    = optional(map(string))
  }))
  default = {
    fe = {
      repository_id  = "pinhouse-dev-fe"
      format         = "DOCKER"
      description    = "개발 환경용 프런트엔드 이미지 저장소"
      immutable_tags = false
    }
    be = {
      repository_id  = "pinhouse-dev-be"
      format         = "DOCKER"
      description    = "개발 환경용 백엔드 이미지 저장소"
      immutable_tags = false
    }
  }
}

variable "artifact_registry_repository_iam_bindings" {
  description = "Artifact Registry 저장소 IAM 바인딩 정의 목록입니다."
  type = map(object({
    repository_key = string
    role           = string
    members        = list(string)
  }))
  default = {}
}

variable "artifact_registry_repository_iam_members" {
  description = "Artifact Registry 저장소 IAM 멤버 정의 목록입니다."
  type = map(object({
    repository_key = string
    role           = string
    member         = string
  }))
  default = {}
}

# ========================================
# Secret Manager 관련 변수
# ========================================
variable "secret_manager_secret_ids" {
  description = "생성할 Secret Manager 비밀 ID 목록입니다."
  type        = list(string)
  default     = []
}

variable "secret_manager_secret_iam_bindings" {
  description = "Secret Manager 비밀 IAM 바인딩 정의 목록입니다."
  type = map(object({
    secret_id = string
    role      = string
    members   = list(string)
  }))
  default = {}
}

variable "secret_manager_secret_iam_members" {
  description = "Secret Manager 비밀 IAM 멤버 정의 목록입니다."
  type = map(object({
    secret_id = string
    role      = string
    member    = string
  }))
  default = {}
}

# ========================================
# Private Google Access 관련 변수
# ========================================
variable "google_api_domain_option" {
  description = "Artifact Registry와 Google APIs에 사용할 Private Google Access 도메인 옵션입니다."
  type        = string
  default     = "private.googleapis.com"

  validation {
    condition     = contains(["private.googleapis.com", "restricted.googleapis.com"], var.google_api_domain_option)
    error_message = "google_api_domain_option은 private.googleapis.com 또는 restricted.googleapis.com 중 하나여야 합니다."
  }
}

# ========================================
# 스토리지 관련 변수
# ========================================
variable "create_storage_buckets" {
  description = "스토리지 버킷 생성 여부입니다."
  type        = bool
  default     = true
}

variable "storage_location" {
  description = "스토리지 버킷을 생성할 위치입니다."
  type        = string
  default     = "ASIA-NORTHEAST3"
}

# ========================================
# 컴퓨트 관련 변수
# ========================================
variable "create_web_instances" {
  description = "웹 인스턴스 생성 여부입니다."
  type        = bool
  default     = true
}

variable "web_machine_type" {
  description = "웹 서버에 사용할 머신 타입입니다."
  type        = string
  default     = "e2-small" # 개발 환경에 맞춘 소형 인스턴스입니다.
}

variable "web_source_image" {
  description = "웹 서버 부팅 디스크에 사용할 이미지입니다."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "enable_web_external_ip" {
  description = "웹 인스턴스 외부 IP 할당 여부입니다. false면 IAP와 Cloud NAT 기반 운영을 전제로 합니다."
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "인스턴스에 연결할 서비스 계정 이메일입니다."
  type        = string
  default     = null
}

# ========================================
# 로드 밸런서 관련 변수
# ========================================
variable "create_load_balancer" {
  description = "로드 밸런서 생성 여부입니다."
  type        = bool
  default     = false
}

# ========================================
# 공통 태그 변수
# ========================================
variable "common_tags" {
  description = "공통 태그입니다."
  type        = map(string)
  default = {
    Project     = "pinhouse"
    Environment = "dev"
    Version     = "v1"
    ManagedBy   = "terraform"
  }
}
