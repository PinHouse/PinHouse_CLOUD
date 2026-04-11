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

output "vpc_self_link" {
  description = "생성된 VPC 네트워크 self link입니다."
  value       = module.vpc.vpc_self_link
}

output "subnets" {
  description = "생성된 서브넷 정보입니다."
  value       = module.vpc.subnets
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

# ========================================
# 웹 서버 출력값
# ========================================
output "web_instances" {
  description = "생성된 웹 인스턴스 정보입니다."
  value       = module.web_servers.instances
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
    enabled       = var.enable_iap_ssh
    members       = module.iap_access.iap_access_members
    admin_members = module.iap_access.iap_admin_members
  }
}
