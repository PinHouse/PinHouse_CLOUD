# ========================================
# VPC 출력값
# ========================================
output "vpc_id" {
  description = "생성된 VPC 네트워크 ID입니다."
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "생성된 VPC 네트워크 이름입니다."
  value       = module.vpc.vpc_name
}

output "subnets" {
  description = "생성된 서브넷 정보입니다."
  value       = module.vpc.subnets
}

# ========================================
# Kubernetes 출력값
# ========================================
output "k8s_master_instances" {
  description = "생성된 Kubernetes 마스터 인스턴스 정보입니다."
  value       = module.k8s_master_nodes.instances
}

output "k8s_worker_instances" {
  description = "생성된 Kubernetes 워커 인스턴스 정보입니다."
  value       = module.k8s_worker_nodes.instances
}

output "k8s_master_instance_group_id" {
  description = "생성된 Kubernetes 마스터 인스턴스 그룹 ID입니다."
  value       = module.k8s_master_nodes.instance_group_id
}

output "k8s_worker_instance_group_id" {
  description = "생성된 Kubernetes 워커 인스턴스 그룹 ID입니다."
  value       = module.k8s_worker_nodes.instance_group_id
}

output "instance_group_id" {
  description = "생성된 Kubernetes 워커 인스턴스 그룹 ID입니다."
  value       = module.k8s_worker_nodes.instance_group_id
}

# ========================================
# 스토리지 출력값
# ========================================
output "storage_buckets" {
  description = "생성된 스토리지 버킷 정보입니다."
  value       = module.storage.buckets
}

output "bucket_urls" {
  description = "생성된 버킷 URL 목록입니다."
  value       = module.storage.bucket_urls
}

# ========================================
# Artifact Registry 출력값
# ========================================
output "artifact_registry_repositories" {
  description = "생성된 Artifact Registry 저장소 정보입니다."
  value       = module.artifact_registry.repositories
}

output "artifact_registry_docker_repository_urls" {
  description = "생성된 Docker Artifact Registry 저장소 URL 목록입니다."
  value       = module.artifact_registry.docker_repository_urls
}

# ========================================
# 로드 밸런서 출력값
# ========================================
output "load_balancer_ip" {
  description = "로드 밸런서 IP 주소입니다."
  value       = var.create_load_balancer ? module.load_balancer[0].forwarding_rule_ip_address : null
}

# ========================================
# IAP 접근 출력값
# ========================================
output "iap_ssh_configuration" {
  description = "IAP SSH 접근 구성 정보입니다."
  value = {
    enabled           = var.enable_iap_ssh
    source_ranges     = var.enable_iap_ssh ? var.iap_ssh_source_ranges : []
    target_tags       = var.management_target_tags
    members           = module.iap_access.iap_access_members
    admin_members     = module.iap_access.iap_admin_members
    direct_ssh_ranges = var.ssh_source_ranges
  }
}

# ========================================
# Kubernetes 네트워크 출력값
# ========================================
output "k8s_network_configuration" {
  description = "Kubernetes 및 Calico 네트워크 구성 정보입니다."
  value = {
    pod_cidr       = var.k8s_pod_cidr
    service_cidr   = var.k8s_service_cidr
    calico_version = var.calico_version
    encapsulation  = "IPIP"
  }
}

# ========================================
# Artifact Registry 네트워크 출력값
# ========================================
output "artifact_registry_private_access" {
  description = "Artifact Registry용 Private Google Access 구성 정보입니다."
  value = {
    domain_option                  = module.artifact_registry_private_access.google_api_domain_option
    googleapis_private_zone_name   = module.artifact_registry_private_access.googleapis_private_zone_name
    pkg_dev_private_zone_name      = module.artifact_registry_private_access.pkg_dev_private_zone_name
    google_api_route_name          = module.artifact_registry_private_access.google_api_route_name
    direct_connectivity_route_name = module.artifact_registry_private_access.google_api_direct_connectivity_route_name
  }
}
