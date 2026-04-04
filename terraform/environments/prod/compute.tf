# ========================================
# Kubernetes 마스터 노드 컴퓨트 모듈
# ========================================
module "k8s_master_nodes" {
  source = "../../modules/compute"

  name_prefix = "${var.project}-${var.environment}-k8s-master"
  network     = module.vpc.vpc_self_link
  subnetwork  = module.vpc.subnets["app"].self_link

  # 관리형 인스턴스 그룹 설정
  create_instance_template = true
  create_instance_group    = true

  instance_group_zone        = "${var.region}-a"
  instance_group_target_size = var.k8s_master_instance_group_size

  # 마스터 노드는 단일 인스턴스로 고정 운영합니다.
  enable_autoscaling = false

  # 공통 인스턴스 설정
  machine_type       = var.k8s_master_machine_type
  source_image       = var.k8s_node_source_image
  boot_disk_size_gb  = var.k8s_node_boot_disk_size_gb
  boot_disk_type     = "pd-balanced"
  enable_external_ip = false
  tags               = ["k8s-master", var.environment]

  # 태그
  common_tags = merge(var.common_tags, {
    Service = "Kubernetes"
    Role    = "Master"
  })

  # 서비스 계정 설정
  service_account_email = var.service_account_email
  service_account_scopes = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}

# ========================================
# Kubernetes 워커 노드 컴퓨트 모듈
# ========================================
module "k8s_worker_nodes" {
  source = "../../modules/compute"

  name_prefix = "${var.project}-${var.environment}-k8s-worker"
  network     = module.vpc.vpc_self_link
  subnetwork  = module.vpc.subnets["web"].self_link

  # 관리형 인스턴스 그룹 설정
  create_instance_template = true
  create_instance_group    = true

  instance_group_zone        = "${var.region}-a"
  instance_group_target_size = var.k8s_worker_instance_group_size

  # 워커 노드는 비용 절감을 우선하되 필요 시에만 오토스케일링합니다.
  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_replicas = var.autoscaling_min_replicas
  autoscaling_max_replicas = var.autoscaling_max_replicas
  autoscaling_cpu_target   = 0.7

  # 공통 인스턴스 설정
  machine_type       = var.k8s_worker_machine_type
  source_image       = var.k8s_node_source_image
  boot_disk_size_gb  = var.k8s_node_boot_disk_size_gb
  boot_disk_type     = "pd-balanced"
  enable_external_ip = false
  tags               = ["k8s-worker", var.environment]

  # 태그
  common_tags = merge(var.common_tags, {
    Service = "Kubernetes"
    Role    = "Worker"
  })

  # 서비스 계정 설정
  service_account_email = var.service_account_email
  service_account_scopes = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}
