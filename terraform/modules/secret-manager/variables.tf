# ========================================
# Secret Manager 기본 변수
# ========================================
variable "project_id" {
  description = "Secret Manager를 생성할 GCP 프로젝트 ID입니다."
  type        = string
}

variable "common_tags" {
  description = "모든 Secret Manager 리소스에 공통 적용할 태그입니다."
  type        = map(string)
  default     = {}
}

# ========================================
# Secret 정의 변수
# ========================================
variable "secret_ids" {
  description = "생성할 Secret Manager secret ID 목록입니다."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for secret_id in var.secret_ids : length(regexall("^[A-Za-z0-9_-]{1,255}$", secret_id)) > 0
    ])
    error_message = "secret_ids 값은 1~255자의 영문 대소문자, 숫자, 밑줄(_), 하이픈(-)만 사용할 수 있습니다."
  }
}

# ========================================
# Secret IAM 변수
# ========================================
variable "secret_iam_bindings" {
  description = "secret별 IAM 바인딩 정의 목록입니다."
  type = map(object({
    secret_id = string
    role      = string
    members   = list(string)
  }))
  default = {}
}

variable "secret_iam_members" {
  description = "secret별 IAM 멤버 정의 목록입니다."
  type = map(object({
    secret_id = string
    role      = string
    member    = string
  }))
  default = {}
}
