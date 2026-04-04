# ========================================
# 프로젝트 기본 변수
# ========================================
variable "project_id" {
  description = "IAP 및 OS Login IAM 권한을 적용할 GCP 프로젝트 ID입니다."
  type        = string
}

variable "enable_iap_ssh" {
  description = "IAP TCP 터널 기반 SSH 접근 구성 여부입니다."
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "접속 대상 인스턴스에 연결된 서비스 계정 이메일입니다."
  type        = string
  default     = null
}

# ========================================
# IAP 접근 주체 변수
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
