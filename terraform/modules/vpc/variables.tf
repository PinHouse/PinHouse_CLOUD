# ========================================
# VPC 기본 변수
# ========================================
variable "vpc_name" {
  description = "생성할 VPC 네트워크 이름입니다."
  type        = string
}

variable "description" {
  description = "VPC 네트워크 설명입니다."
  type        = string
  default     = "Terraform로 관리되는 VPC 네트워크"
}

variable "routing_mode" {
  description = "VPC 라우팅 모드입니다. REGIONAL 또는 GLOBAL을 사용합니다."
  type        = string
  default     = "REGIONAL"
}

# ========================================
# 서브넷 및 방화벽 변수
# ========================================
variable "subnets" {
  description = "생성할 서브넷 정의 목록입니다."
  type = map(object({
    name                     = string
    ip_cidr_range            = string
    region                   = string
    description              = string
    private_ip_google_access = optional(bool)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })))
  }))
  default = {}
}

variable "firewall_rules" {
  description = "생성할 방화벽 규칙 정의 목록입니다."
  type = map(object({
    name = string
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    source_ranges = optional(list(string))
    source_tags   = optional(list(string))
    target_tags   = optional(list(string))
    priority      = optional(number)
  }))
  default = {}
}

# ========================================
# Cloud NAT 관련 변수
# ========================================
variable "enable_nat" {
  description = "Cloud NAT 사용 여부입니다."
  type        = bool
  default     = false
}

variable "nat_region" {
  description = "Cloud NAT를 생성할 리전입니다."
  type        = string
  default     = "asia-northeast3"
}

variable "router_asn" {
  description = "Cloud Router에 사용할 ASN 번호입니다."
  type        = number
  default     = 64514
}

variable "nat_log_enable" {
  description = "NAT 로그 활성화 여부입니다."
  type        = bool
  default     = false
}

variable "nat_log_filter" {
  description = "NAT 로그 필터입니다. ERRORS_ONLY, TRANSLATIONS_ONLY, ALL 중 하나를 사용합니다."
  type        = string
  default     = "ERRORS_ONLY"
}
