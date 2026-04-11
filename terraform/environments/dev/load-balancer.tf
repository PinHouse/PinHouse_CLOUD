# ========================================
# 외부 프록시 NLB 기본 로컬 값
# ========================================
locals {
  load_balancer_name_prefix = "${var.project}-${var.environment}-nlb"
}

# ========================================
# 외부 프록시 NLB용 proxy-only 서브넷
# ========================================
resource "google_compute_subnetwork" "load_balancer_proxy_only" {
  count = var.create_load_balancer ? 1 : 0

  name          = "${local.load_balancer_name_prefix}-proxy-only-subnet"
  ip_cidr_range = var.load_balancer_proxy_only_subnet_cidr
  region        = var.region
  network       = module.vpc.vpc_self_link
  description   = "개발 환경 외부 프록시 NLB용 proxy-only subnet"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# ========================================
# 외부 프록시 NLB 공인 IP
# ========================================
resource "google_compute_address" "load_balancer_ip" {
  count = var.create_load_balancer ? 1 : 0

  name         = "${local.load_balancer_name_prefix}-ip"
  region       = var.region
  network_tier = "PREMIUM"
}

# ========================================
# HTTP NodePort 헬스 체크
# ========================================
resource "google_compute_region_health_check" "nginx_gateway_http" {
  count = var.create_load_balancer ? 1 : 0

  name                = "${local.load_balancer_name_prefix}-http-health-check"
  region              = var.region
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = var.nginx_gateway_http_node_port
  }
}

# ========================================
# HTTPS NodePort 헬스 체크
# ========================================
resource "google_compute_region_health_check" "nginx_gateway_https" {
  count = var.create_load_balancer ? 1 : 0

  name                = "${local.load_balancer_name_prefix}-https-health-check"
  region              = var.region
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = var.nginx_gateway_https_node_port
  }
}

# ========================================
# HTTP 백엔드 서비스
# ========================================
resource "google_compute_region_backend_service" "nginx_gateway_http" {
  count = var.create_load_balancer ? 1 : 0

  name                  = "${local.load_balancer_name_prefix}-http-backend-service"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "ngf-http"
  timeout_sec           = 30
  session_affinity      = "CLIENT_IP"
  health_checks         = [google_compute_region_health_check.nginx_gateway_http[0].id]

  backend {
    group           = module.k8s_worker_nodes.instance_group_instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.6
    capacity_scaler = 1.0
  }
}

# ========================================
# HTTPS 백엔드 서비스
# ========================================
resource "google_compute_region_backend_service" "nginx_gateway_https" {
  count = var.create_load_balancer ? 1 : 0

  name                  = "${local.load_balancer_name_prefix}-https-backend-service"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_name             = "ngf-https"
  timeout_sec           = 30
  session_affinity      = "CLIENT_IP"
  health_checks         = [google_compute_region_health_check.nginx_gateway_https[0].id]

  backend {
    group           = module.k8s_worker_nodes.instance_group_instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

# ========================================
# HTTP 타깃 TCP 프록시
# ========================================
resource "google_compute_region_target_tcp_proxy" "nginx_gateway_http" {
  count = var.create_load_balancer ? 1 : 0

  name            = "${local.load_balancer_name_prefix}-http-proxy"
  region          = var.region
  backend_service = google_compute_region_backend_service.nginx_gateway_http[0].id
}

# ========================================
# HTTPS 타깃 TCP 프록시
# ========================================
resource "google_compute_region_target_tcp_proxy" "nginx_gateway_https" {
  count = var.create_load_balancer ? 1 : 0

  name            = "${local.load_balancer_name_prefix}-https-proxy"
  region          = var.region
  backend_service = google_compute_region_backend_service.nginx_gateway_https[0].id
}

# ========================================
# HTTP 포워딩 규칙
# ========================================
resource "google_compute_forwarding_rule" "nginx_gateway_http" {
  count = var.create_load_balancer ? 1 : 0

  name                  = "${local.load_balancer_name_prefix}-http-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network               = module.vpc.vpc_self_link
  port_range            = "80"
  target                = google_compute_region_target_tcp_proxy.nginx_gateway_http[0].id
  network_tier          = "PREMIUM"
  ip_address            = google_compute_address.load_balancer_ip[0].address

  depends_on = [google_compute_subnetwork.load_balancer_proxy_only]
}

# ========================================
# HTTPS 포워딩 규칙
# ========================================
resource "google_compute_forwarding_rule" "nginx_gateway_https" {
  count = var.create_load_balancer ? 1 : 0

  name                  = "${local.load_balancer_name_prefix}-https-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network               = module.vpc.vpc_self_link
  port_range            = "443"
  target                = google_compute_region_target_tcp_proxy.nginx_gateway_https[0].id
  network_tier          = "PREMIUM"
  ip_address            = google_compute_address.load_balancer_ip[0].address

  depends_on = [google_compute_subnetwork.load_balancer_proxy_only]
}
