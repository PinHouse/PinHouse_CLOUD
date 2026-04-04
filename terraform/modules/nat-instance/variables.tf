# ========================================
# NAT 인스턴스 기본 변수
# ========================================
variable "name_prefix" {
  description = "NAT 인스턴스 관련 리소스 이름 접두사입니다."
  type        = string
}

variable "network" {
  description = "NAT 인스턴스가 연결될 VPC 네트워크 self_link 또는 이름입니다."
  type        = string
}

variable "subnetwork" {
  description = "NAT 인스턴스가 연결될 서브넷 self_link 또는 이름입니다."
  type        = string
}

variable "zone" {
  description = "NAT 인스턴스를 생성할 존입니다."
  type        = string
}

# ========================================
# 인스턴스 사양 변수
# ========================================
variable "machine_type" {
  description = "NAT 인스턴스에 사용할 머신 타입입니다."
  type        = string
  default     = "e2-micro"
}

variable "source_image" {
  description = "NAT 인스턴스 부팅 디스크에 사용할 이미지입니다."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "boot_disk_size_gb" {
  description = "NAT 인스턴스 부팅 디스크 크기(GB)입니다."
  type        = number
  default     = 10
}

variable "boot_disk_type" {
  description = "NAT 인스턴스 부팅 디스크 타입입니다."
  type        = string
  default     = "pd-balanced"
}

variable "network_tier" {
  description = "NAT 인스턴스 외부 IP에 사용할 네트워크 티어입니다."
  type        = string
  default     = "PREMIUM"
}

# ========================================
# 라우팅 및 방화벽 변수
# ========================================
variable "nat_instance_tag" {
  description = "NAT 인스턴스 자체에 부여할 네트워크 태그입니다."
  type        = string
  default     = "nat-instance"
}

variable "route_tags" {
  description = "이 태그를 가진 인스턴스만 NAT 인스턴스를 기본 경로로 사용합니다."
  type        = list(string)
  default     = ["private-egress"]

  validation {
    condition     = length(var.route_tags) > 0
    error_message = "route_tags에는 최소 1개의 태그가 필요합니다."
  }
}

variable "internal_source_ranges" {
  description = "NAT 인스턴스로 전달할 내부 트래픽의 소스 CIDR 목록입니다."
  type        = list(string)

  validation {
    condition     = length(var.internal_source_ranges) > 0
    error_message = "internal_source_ranges에는 최소 1개의 CIDR이 필요합니다."
  }
}

variable "route_destination_range" {
  description = "NAT 인스턴스로 보낼 목적지 CIDR입니다."
  type        = string
  default     = "0.0.0.0/0"
}

variable "route_priority" {
  description = "NAT 인스턴스 기본 경로 우선순위입니다."
  type        = number
  default     = 900
}

# ========================================
# 메타데이터 및 부가 설정 변수
# ========================================
variable "tags" {
  description = "NAT 인스턴스에 추가로 부여할 네트워크 태그 목록입니다."
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "NAT 인스턴스에 부여할 공통 태그입니다."
  type        = map(string)
  default     = {}
}

variable "metadata" {
  description = "NAT 인스턴스에 부여할 메타데이터입니다."
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "NAT 인스턴스에 연결할 서비스 계정 이메일입니다."
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "서비스 계정에 부여할 OAuth 스코프 목록입니다."
  type        = list(string)
  default     = ["cloud-platform"]
}
