# ========================================
# 기본 연결 변수
# ========================================
variable "name_prefix" {
  description = "리소스 이름 접두사입니다."
  type        = string
}

variable "network" {
  description = "인스턴스가 연결될 VPC 네트워크입니다."
  type        = string
}

variable "subnetwork" {
  description = "인스턴스가 연결될 서브넷입니다."
  type        = string
}

# ========================================
# 인스턴스 템플릿 및 공통 사양 변수
# ========================================
variable "create_instance_template" {
  description = "인스턴스 템플릿 생성 여부입니다."
  type        = bool
  default     = false
}

variable "template_description" {
  description = "인스턴스 템플릿 설명입니다."
  type        = string
  default     = "Terraform로 관리되는 인스턴스 템플릿"
}

variable "machine_type" {
  description = "기본 GCE 인스턴스 머신 타입입니다."
  type        = string
  default     = "e2-medium"
}

variable "source_image" {
  description = "부팅 디스크에 사용할 기본 이미지입니다."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "boot_disk_size_gb" {
  description = "부팅 디스크 크기(GB)입니다."
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "부팅 디스크 타입입니다. pd-standard, pd-ssd, pd-balanced 중 하나를 사용합니다."
  type        = string
  default     = "pd-balanced"
}

variable "enable_external_ip" {
  description = "외부 IP 할당 여부입니다."
  type        = bool
  default     = false
}

variable "network_tier" {
  description = "외부 IP에 사용할 네트워크 티어입니다. PREMIUM 또는 STANDARD를 사용합니다."
  type        = string
  default     = "PREMIUM"
}

# ========================================
# 메타데이터 및 서비스 계정 변수
# ========================================
variable "metadata" {
  description = "인스턴스 공통 메타데이터입니다."
  type        = map(string)
  default     = {}
}

variable "enable_os_login" {
  description = "OS Login 메타데이터 값입니다."
  type        = string
  default     = "TRUE"
}

variable "startup_script" {
  description = "인스턴스 시작 시 실행할 스크립트입니다."
  type        = string
  default     = null
}

variable "service_account_email" {
  description = "인스턴스에 연결할 서비스 계정 이메일입니다."
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "서비스 계정에 부여할 OAuth 스코프 목록입니다."
  type        = list(string)
  default     = ["cloud-platform"]
}

# ========================================
# 태그 및 개별 인스턴스 변수
# ========================================
variable "tags" {
  description = "인스턴스에 적용할 네트워크 태그 목록입니다."
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "인스턴스에 적용할 공통 태그입니다."
  type        = map(string)
  default     = {}
}

variable "preemptible" {
  description = "선점형 인스턴스 사용 여부입니다."
  type        = bool
  default     = false
}

variable "instances" {
  description = "생성할 개별 인스턴스 정의 목록입니다."
  type = map(object({
    name                = string
    zone                = string
    machine_type        = optional(string)
    source_image        = optional(string)
    boot_disk_size_gb   = optional(number)
    boot_disk_type      = optional(string)
    enable_external_ip  = optional(bool)
    external_ip         = optional(string)
    metadata            = optional(map(string))
    startup_script      = optional(string)
    tags                = optional(list(string))
    common_tags         = optional(map(string))
    deletion_protection = optional(bool)
  }))
  default = {}
}

# ========================================
# 관리형 인스턴스 그룹 변수
# ========================================
variable "create_instance_group" {
  description = "관리형 인스턴스 그룹 생성 여부입니다."
  type        = bool
  default     = false
}

variable "instance_group_zone" {
  description = "관리형 인스턴스 그룹을 생성할 존입니다."
  type        = string
  default     = "asia-northeast3-a"
}

variable "instance_group_target_size" {
  description = "관리형 인스턴스 그룹의 목표 인스턴스 수입니다."
  type        = number
  default     = 1
}

variable "health_check_name" {
  description = "자동 복구 정책에 연결할 헬스 체크 리소스 이름입니다."
  type        = string
  default     = null
}

variable "health_check_initial_delay" {
  description = "자동 복구 정책의 초기 대기 시간(초)입니다."
  type        = number
  default     = 300
}

variable "named_ports" {
  description = "관리형 인스턴스 그룹에 설정할 Named Port 목록입니다."
  type = list(object({
    name = string
    port = number
  }))
  default = []
}

variable "update_policy_type" {
  description = "업데이트 정책 타입입니다. OPPORTUNISTIC 또는 PROACTIVE를 사용합니다."
  type        = string
  default     = "PROACTIVE"
}

variable "update_minimal_action" {
  description = "업데이트 시 최소 수행 동작입니다. REPLACE, RESTART, REFRESH 중 하나를 사용합니다."
  type        = string
  default     = "REPLACE"
}

variable "max_surge_fixed" {
  description = "업데이트 시 허용할 최대 초과 인스턴스 수입니다."
  type        = number
  default     = 3
}

variable "max_unavailable_fixed" {
  description = "업데이트 시 허용할 최대 비가용 인스턴스 수입니다."
  type        = number
  default     = 0
}

# ========================================
# 오토스케일링 변수
# ========================================
variable "enable_autoscaling" {
  description = "오토스케일링 사용 여부입니다."
  type        = bool
  default     = false
}

variable "autoscaling_min_replicas" {
  description = "오토스케일링 최소 인스턴스 수입니다."
  type        = number
  default     = 1
}

variable "autoscaling_max_replicas" {
  description = "오토스케일링 최대 인스턴스 수입니다."
  type        = number
  default     = 10
}

variable "autoscaling_cooldown_period" {
  description = "오토스케일링 쿨다운 시간(초)입니다."
  type        = number
  default     = 60
}

variable "autoscaling_cpu_target" {
  description = "CPU 기반 오토스케일링 목표 사용률입니다. 0.0에서 1.0 사이 값을 사용합니다."
  type        = number
  default     = null
}
