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
  default     = ["k8s-master", "k8s-worker"]
}

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

variable "enable_nat" {
  description = "Cloud NAT 사용 여부입니다."
  type        = bool
  default     = true
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
      repository_id  = "pinhouse-prod-fe"
      format         = "DOCKER"
      description    = "프로덕션 환경용 프런트엔드 이미지 저장소"
      immutable_tags = false
    }
    be = {
      repository_id  = "pinhouse-prod-be"
      format         = "DOCKER"
      description    = "프로덕션 환경용 백엔드 이미지 저장소"
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
# 컴퓨트 관련 변수
# ========================================
variable "k8s_master_instance_group_size" {
  description = "Kubernetes 마스터 관리형 인스턴스 그룹의 목표 인스턴스 수입니다."
  type        = number
  default     = 1
}

variable "k8s_worker_instance_group_size" {
  description = "Kubernetes 워커 관리형 인스턴스 그룹의 목표 인스턴스 수입니다."
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

variable "k8s_master_machine_type" {
  description = "Kubernetes 마스터 노드에 사용할 머신 타입입니다."
  type        = string
  default     = "e2-custom-2-4096"
}

variable "k8s_worker_machine_type" {
  description = "Kubernetes 워커 노드에 사용할 머신 타입입니다."
  type        = string
  default     = "e2-custom-2-4096"
}

variable "k8s_node_boot_disk_size_gb" {
  description = "Kubernetes 노드 부팅 디스크 크기(GB)입니다."
  type        = number
  default     = 50
}

variable "k8s_node_source_image" {
  description = "Kubernetes 노드 부팅 디스크에 사용할 이미지입니다."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "k8s_pod_cidr" {
  description = "Kubernetes Pod CIDR 대역입니다. Calico IPPool과 kubeadm podSubnet에 동일하게 사용합니다."
  type        = string
  default     = "192.168.0.0/16"
}

variable "k8s_service_cidr" {
  description = "Kubernetes Service CIDR 대역입니다."
  type        = string
  default     = "10.96.0.0/12"
}

variable "calico_version" {
  description = "초기 설치에 사용할 Calico 오픈소스 릴리스 버전입니다."
  type        = string
  default     = "v3.31.4"
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
  default     = "ASIA-NORTHEAST3"
}

variable "allowed_cors_origins" {
  description = "정적 자산 버킷에서 허용할 CORS Origin 목록입니다."
  type        = list(string)
  default     = []
}

# ========================================
# 로드 밸런서 관련 변수
# ========================================
variable "create_load_balancer" {
  description = "로드 밸런서 생성 여부입니다."
  type        = bool
  default     = true
}

# ========================================
# 공통 태그 변수
# ========================================
variable "common_tags" {
  description = "공통 태그입니다."
  type        = map(string)
  default = {
    project     = "pinhouse"
    environment = "prod"
    version     = "v1"
    managed_by  = "terraform"
  }
}
