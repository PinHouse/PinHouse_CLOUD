# ========================================
# Private Google Access 기본 변수
# ========================================
variable "project_id" {
  description = "Private Google Access 관련 리소스를 생성할 GCP 프로젝트 ID입니다."
  type        = string
}

variable "network_self_link" {
  description = "Private DNS zone을 연결할 VPC 네트워크 self_link입니다."
  type        = string
}

variable "name_prefix" {
  description = "생성할 DNS 및 라우트 리소스 이름 접두사입니다."
  type        = string
}

variable "google_api_domain_option" {
  description = "Private Google Access에 사용할 Google API 도메인 옵션입니다."
  type        = string
  default     = "private.googleapis.com"

  validation {
    condition     = contains(["private.googleapis.com", "restricted.googleapis.com"], var.google_api_domain_option)
    error_message = "google_api_domain_option은 private.googleapis.com 또는 restricted.googleapis.com 중 하나여야 합니다."
  }
}

variable "route_tags" {
  description = "특정 태그가 붙은 인스턴스에만 Google API 전용 라우트를 적용할 때 사용할 태그 목록입니다."
  type        = list(string)
  default     = []
}

variable "route_priority" {
  description = "Google API 전용 라우트 우선순위입니다."
  type        = number
  default     = 800
}

variable "create_direct_connectivity_route" {
  description = "Google 문서에서 권장하는 직접 연결 대역 라우트 생성 여부입니다."
  type        = bool
  default     = true
}
