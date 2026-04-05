# ========================================
# Artifact Registry 기본 변수
# ========================================
variable "project_id" {
  description = "Artifact Registry를 생성할 GCP 프로젝트 ID입니다."
  type        = string
}

variable "default_location" {
  description = "저장소 기본 생성 위치입니다."
  type        = string
  default     = "asia-northeast3"
}

variable "common_tags" {
  description = "모든 저장소에 공통 적용할 태그입니다."
  type        = map(string)
  default     = {}
}

# ========================================
# 저장소 정의 변수
# ========================================
variable "repositories" {
  description = "생성할 Artifact Registry 저장소 정의 목록입니다."
  type = map(object({
    repository_id  = string
    format         = string
    description    = optional(string)
    location       = optional(string)
    immutable_tags = optional(bool)
    common_tags    = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : contains(
        ["DOCKER", "MAVEN", "NPM", "APT", "YUM", "PYTHON", "KFP", "GO", "GENERIC"],
        upper(repository.format)
      )
    ])
    error_message = "repositories[*].format은 DOCKER, MAVEN, NPM, APT, YUM, PYTHON, KFP, GO, GENERIC 중 하나여야 합니다."
  }
}

# ========================================
# 저장소 IAM 변수
# ========================================
variable "repository_iam_bindings" {
  description = "저장소별 IAM 바인딩 정의 목록입니다."
  type = map(object({
    repository_key = string
    role           = string
    members        = list(string)
  }))
  default = {}
}

variable "repository_iam_members" {
  description = "저장소별 IAM 멤버 정의 목록입니다."
  type = map(object({
    repository_key = string
    role           = string
    member         = string
  }))
  default = {}
}
