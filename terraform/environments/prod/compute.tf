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
  startup_script = templatefile("${path.module}/scripts/k8s-master-init.sh", {
    k8s_pod_cidr     = var.k8s_pod_cidr
    k8s_service_cidr = var.k8s_service_cidr
    calico_version   = var.calico_version
  })
  tags = ["k8s-master", var.environment]

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

  # 서브넷 이동은 MIG 인플레이스 업데이트가 불가하므로 새 이름으로 교체합니다.
  name_prefix = "${var.project}-${var.environment}-k8s-workers"
  network     = module.vpc.vpc_self_link
  subnetwork  = module.vpc.subnets["app"].self_link

  # 관리형 인스턴스 그룹 설정
  create_instance_template = true
  create_instance_group    = true

  instance_group_zone        = "${var.region}-a"
  instance_group_target_size = var.k8s_worker_instance_group_size

  # target_size가 0이면 워커 MIG를 완전히 비워둘 수 있도록 오토스케일러를 비활성화합니다.
  enable_autoscaling       = var.k8s_worker_instance_group_size > 0 ? var.enable_autoscaling : false
  autoscaling_min_replicas = var.autoscaling_min_replicas
  autoscaling_max_replicas = var.autoscaling_max_replicas
  autoscaling_cpu_target   = 0.7

  # 공통 인스턴스 설정
  machine_type       = var.k8s_worker_machine_type
  source_image       = var.k8s_node_source_image
  boot_disk_size_gb  = var.k8s_node_boot_disk_size_gb
  boot_disk_type     = "pd-balanced"
  enable_external_ip = false
  startup_script     = file("${path.module}/scripts/k8s-worker-init.sh")
  named_ports = [
    {
      name = "ngf-http"
      port = var.nginx_gateway_http_node_port
    },
    {
      name = "ngf-https"
      port = var.nginx_gateway_https_node_port
    }
  ]
  tags = ["k8s-worker", var.environment]

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
