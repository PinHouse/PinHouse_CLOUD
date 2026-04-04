# ========================================
# 프로젝트 기본 변수
# ========================================
variable "project_id" {
  description = "배포 대상 GCP 프로젝트 ID입니다."
  type        = string
  default     = "prod-pinhouse"
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
  default     = "prod"
}

# ========================================
# VPC 관련 변수
# ========================================
variable "vpc_name" {
  description = "생성할 VPC 네트워크 이름입니다."
  type        = string
  default     = "prod-vpc"
}

variable "ssh_source_ranges" {
  description = "SSH 접근을 허용할 CIDR 목록입니다."
  type        = list(string)
  default     = [] # 운영 환경에서는 반드시 허용 대역을 명시해야 합니다.
}

variable "enable_nat" {
  description = "Cloud NAT 사용 여부입니다."
  type        = bool
  default     = true
}

# ========================================
# 컴퓨트 관련 변수
# ========================================
variable "use_instance_group" {
  description = "관리형 인스턴스 그룹 사용 여부입니다."
  type        = bool
  default     = true
}

variable "create_web_instances" {
  description = "개별 웹 인스턴스 생성 여부입니다."
  type        = bool
  default     = true
}

variable "instance_group_size" {
  description = "관리형 인스턴스 그룹의 목표 인스턴스 수입니다."
  type        = number
  default     = 2
}

variable "enable_autoscaling" {
  description = "오토스케일링 사용 여부입니다."
  type        = bool
  default     = true
}

variable "autoscaling_min_replicas" {
  description = "오토스케일링 최소 인스턴스 수입니다."
  type        = number
  default     = 2
}

variable "autoscaling_max_replicas" {
  description = "오토스케일링 최대 인스턴스 수입니다."
  type        = number
  default     = 5
}

variable "web_machine_type" {
  description = "웹 서버에 사용할 머신 타입입니다."
  type        = string
  default     = "e2-standard-2" # 운영 환경에 맞춘 고성능 인스턴스입니다.
}

variable "web_machine_ssd" {
  description = "웹 서버 부팅 디스크 크기(GB)입니다."
  type        = number
  default     = 50
}

variable "web_source_image" {
  description = "웹 서버 부팅 디스크에 사용할 이미지입니다."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "service_account_email" {
  description = "인스턴스에 연결할 서비스 계정 이메일입니다."
  type        = string
  default     = null
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
  default     = "ASIA" # 운영 환경에서는 멀티 리전을 기본값으로 사용합니다.
}

variable "allowed_cors_origins" {
  description = "정적 자산 버킷에서 허용할 CORS Origin 목록입니다."
  type        = list(string)
  default     = [] # 실제 서비스 도메인을 명시해야 합니다.
}

# ========================================
# 로드 밸런서 관련 변수
# ========================================
variable "create_load_balancer" {
  description = "로드 밸런서 생성 여부입니다."
  type        = bool
  default     = true
}

variable "lb_type" {
  description = "생성할 로드 밸런서 타입입니다. NETWORK, HTTP, HTTPS 중 하나를 사용합니다."
  type        = string
  default     = "NETWORK"
}

variable "ssl_certificates" {
  description = "HTTPS 로드 밸런서에 연결할 SSL 인증서 self_link 목록입니다."
  type        = list(string)
  default     = []
}

# ========================================
# 공통 태그 변수
# ========================================
variable "common_tags" {
  description = "공통 태그입니다."
  type        = map(string)
  default = {
    Project     = "pinhouse"
    Environment = "prod"
    Version     = "v1"
    ManagedBy   = "Terraform"
  }
}
