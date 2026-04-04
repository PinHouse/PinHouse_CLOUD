# ========================================
# 로드 밸런서 기본 변수
# ========================================
variable "name_prefix" {
  description = "리소스 이름 접두사입니다."
  type        = string
}

variable "region" {
  description = "로드 밸런서를 생성할 리전입니다."
  type        = string
  default     = "asia-northeast3"
}

variable "lb_type" {
  description = "로드 밸런서 타입입니다. NETWORK, HTTP, HTTPS 중 하나를 사용합니다."
  type        = string
  default     = "NETWORK"

  validation {
    condition     = contains(["NETWORK", "HTTP", "HTTPS"], var.lb_type)
    error_message = "lb_type은 NETWORK, HTTP, HTTPS 중 하나여야 합니다."
  }
}

# ========================================
# 헬스 체크 변수
# ========================================
variable "create_health_check" {
  description = "헬스 체크 생성 여부입니다."
  type        = bool
  default     = true
}

variable "health_check_protocol" {
  description = "헬스 체크 프로토콜입니다. HTTP, HTTPS, TCP, SSL 중 하나를 사용합니다."
  type        = string
  default     = "HTTP"
}

variable "health_check_port" {
  description = "헬스 체크 포트입니다."
  type        = number
  default     = 80
}

variable "health_check_request_path" {
  description = "HTTP 또는 HTTPS 헬스 체크 요청 경로입니다."
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "헬스 체크 간격(초)입니다."
  type        = number
  default     = 10
}

variable "health_check_timeout" {
  description = "헬스 체크 타임아웃(초)입니다."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "정상 상태로 판단하기 위한 연속 성공 횟수입니다."
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "비정상 상태로 판단하기 위한 연속 실패 횟수입니다."
  type        = number
  default     = 2
}

variable "health_check_ids" {
  description = "기존 헬스 체크 ID 목록입니다. create_health_check가 false일 때 사용합니다."
  type        = list(string)
  default     = []
}

# ========================================
# 백엔드 서비스 변수
# ========================================
variable "backend_protocol" {
  description = "백엔드 서비스 프로토콜입니다. TCP, UDP, SSL 중 하나를 사용합니다."
  type        = string
  default     = "TCP"
}

variable "backend_timeout_sec" {
  description = "백엔드 서비스 타임아웃(초)입니다."
  type        = number
  default     = 30
}

variable "backend_groups" {
  description = "백엔드로 연결할 인스턴스 그룹 또는 NEG 목록입니다."
  type = list(object({
    group           = string
    balancing_mode  = optional(string)
    capacity_scaler = optional(number)
    max_utilization = optional(number)
  }))
  default = []
}

variable "session_affinity" {
  description = "세션 어피니티 방식입니다. NONE, CLIENT_IP, CLIENT_IP_PROTO, CLIENT_IP_PORT_PROTO 중 하나를 사용합니다."
  type        = string
  default     = "NONE"
}

variable "connection_draining_timeout" {
  description = "연결 드레이닝 타임아웃(초)입니다."
  type        = number
  default     = null
}

# ========================================
# 포워딩 규칙 변수
# ========================================
variable "forwarding_rule_ip_protocol" {
  description = "포워딩 규칙에 사용할 IP 프로토콜입니다. TCP 또는 UDP를 사용합니다."
  type        = string
  default     = "TCP"
}

variable "forwarding_rule_port_range" {
  description = "포워딩 규칙 포트 범위입니다. 예를 들어 80 또는 80-443을 사용할 수 있습니다."
  type        = string
  default     = "80"
}

variable "forwarding_rule_ip_address" {
  description = "포워딩 규칙에 연결할 고정 IP 주소입니다."
  type        = string
  default     = null
}

variable "network_tier" {
  description = "네트워크 티어입니다. PREMIUM 또는 STANDARD를 사용합니다."
  type        = string
  default     = "PREMIUM"
}

# ========================================
# HTTPS 및 CDN 관련 변수
# ========================================
variable "ssl_certificates" {
  description = "HTTPS 로드 밸런서에 연결할 SSL 인증서 self_link 목록입니다."
  type        = list(string)
  default     = []
}

variable "enable_cdn" {
  description = "CDN 사용 여부입니다."
  type        = bool
  default     = false
}

variable "cdn_cache_mode" {
  description = "CDN 캐시 모드입니다. CACHE_ALL_STATIC, USE_ORIGIN_HEADERS, FORCE_CACHE_ALL 중 하나를 사용합니다."
  type        = string
  default     = "USE_ORIGIN_HEADERS"
}

variable "cdn_default_ttl" {
  description = "CDN 기본 TTL(초)입니다."
  type        = number
  default     = 3600
}

variable "cdn_max_ttl" {
  description = "CDN 최대 TTL(초)입니다."
  type        = number
  default     = 86400
}

variable "cdn_client_ttl" {
  description = "클라이언트 응답에 사용할 CDN TTL(초)입니다."
  type        = number
  default     = 3600
}

variable "cdn_negative_caching" {
  description = "CDN 네거티브 캐싱 사용 여부입니다."
  type        = bool
  default     = false
}

variable "cdn_serve_while_stale" {
  description = "원본 응답 지연 시 오래된 콘텐츠를 유지할 시간(초)입니다."
  type        = number
  default     = 86400
}
