# ========================================
# VPC 모듈
# ========================================
module "vpc" {
  source = "../../modules/vpc"

  vpc_name     = var.vpc_name
  description  = "개발 환경용 VPC 네트워크"
  routing_mode = "REGIONAL"

  # 서브넷 정의
  subnets = {
    web = {
      name                     = "${var.vpc_name}-web-subnet"
      ip_cidr_range            = "10.0.1.0/24"
      region                   = var.region
      description              = "웹 서버용 서브넷"
      private_ip_google_access = true
    }
    app = {
      name                     = "${var.vpc_name}-app-subnet"
      ip_cidr_range            = "10.0.2.0/24"
      region                   = var.region
      description              = "애플리케이션 서버용 서브넷"
      private_ip_google_access = true
    }
    db = {
      name                     = "${var.vpc_name}-db-subnet"
      ip_cidr_range            = "10.0.3.0/24"
      region                   = var.region
      description              = "데이터베이스용 서브넷"
      private_ip_google_access = true
    }
  }

  # 방화벽 규칙 정의
  firewall_rules = local.dev_firewall_rules

  # Cloud NAT 설정
  enable_nat     = var.enable_nat
  nat_region     = var.region
  router_asn     = 64514
  nat_log_enable = true
  nat_log_filter = "ERRORS_ONLY"
}
