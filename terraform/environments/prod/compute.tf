# ========================================
# 웹 서버 컴퓨트 모듈
# ========================================
module "web_servers" {
  source = "../../modules/compute"

  name_prefix = "${var.project}-${var.environment}-web"
  network     = module.vpc.vpc_self_link
  subnetwork  = module.vpc.subnets["web"].self_link

  # 관리형 인스턴스 그룹 설정
  create_instance_template = var.use_instance_group
  create_instance_group    = var.use_instance_group

  instance_group_zone        = "${var.region}-a"
  instance_group_target_size = var.instance_group_size

  # 오토스케일링 설정
  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_replicas = var.autoscaling_min_replicas
  autoscaling_max_replicas = var.autoscaling_max_replicas
  autoscaling_cpu_target   = 0.7

  # 관리형 인스턴스 그룹을 사용하지 않을 때만 개별 인스턴스를 정의합니다.
  instances = !var.use_instance_group && var.create_web_instances ? tomap({
    web1 = {
      name                = "${var.environment}-web-01"
      zone                = "${var.region}-a"
      machine_type        = var.web_machine_type
      enable_external_ip  = false # 프로덕션 환경은 로드 밸런서를 통한 접근만 허용합니다.
      tags                = ["web-server", var.environment]
      deletion_protection = true # 실수로 삭제되지 않도록 보호합니다.
    }
  }) : tomap({})

  # 공통 인스턴스 설정
  machine_type       = var.web_machine_type
  source_image       = var.web_source_image
  boot_disk_size_gb  = var.web_machine_ssd
  boot_disk_type     = "pd-ssd"
  enable_external_ip = false
  tags               = ["web-server", var.environment]

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
