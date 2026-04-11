# ========================================
# 웹 서버 컴퓨트 모듈
# ========================================
locals {
  web_server_tags = ["web-server", var.environment]
}

module "web_servers" {
  source = "../../modules/compute"

  name_prefix = "${var.environment}-web"
  network     = module.vpc.vpc_self_link
  subnetwork  = module.vpc.subnets["web"].self_link

  # 개별 인스턴스 정의
  instances = var.create_web_instances ? tomap({
    web1 = {
      name               = "${var.environment}-web-01"
      zone               = "${var.region}-a"
      machine_type       = var.web_machine_type
      enable_external_ip = var.enable_web_external_ip
      tags               = local.web_server_tags
    }
  }) : tomap({})

  # 공통 인스턴스 설정
  machine_type       = var.web_machine_type
  source_image       = var.web_source_image
  boot_disk_size_gb  = 20
  boot_disk_type     = "pd-balanced"
  enable_external_ip = var.enable_web_external_ip
  tags               = local.web_server_tags

  # 태그
  common_tags = merge(var.common_tags, {
    Service = "Backend"
  })

  # 서비스 계정 설정
  service_account_email = var.service_account_email
  service_account_scopes = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}
