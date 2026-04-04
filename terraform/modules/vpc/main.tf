# ========================================
# VPC 네트워크 리소스
# ========================================
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  description             = var.description
}

# ========================================
# 서브넷 리소스
# ========================================
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc.id
  description   = each.value.description

  # 설정이 없으면 Private Google Access를 기본 활성화합니다.
  private_ip_google_access = lookup(each.value, "private_ip_google_access", true)

  # 보조 IP 대역이 정의된 경우에만 추가합니다.
  dynamic "secondary_ip_range" {
    for_each = coalesce(lookup(each.value, "secondary_ip_ranges", null), [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

# ========================================
# 방화벽 리소스
# ========================================
resource "google_compute_firewall" "firewall_rules" {
  for_each = var.firewall_rules

  name    = each.value.name
  network = google_compute_network.vpc.name

  # 허용 규칙 정의입니다.
  dynamic "allow" {
    for_each = coalesce(lookup(each.value, "allow", null), [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", null)
    }
  }

  # 차단 규칙 정의입니다.
  dynamic "deny" {
    for_each = coalesce(lookup(each.value, "deny", null), [])
    content {
      protocol = deny.value.protocol
      ports    = lookup(deny.value, "ports", null)
    }
  }

  # 소스 CIDR 목록입니다.
  source_ranges = lookup(each.value, "source_ranges", null)

  # 소스 태그 필터입니다.
  source_tags = lookup(each.value, "source_tags", null)

  # 대상 태그 필터입니다.
  target_tags = lookup(each.value, "target_tags", null)

  # 규칙 우선순위입니다.
  priority = lookup(each.value, "priority", 1000)
}

# ========================================
# Cloud Router 리소스
# ========================================
resource "google_compute_router" "router" {
  count   = var.enable_nat ? 1 : 0
  name    = "${var.vpc_name}-router"
  region  = var.nat_region
  network = google_compute_network.vpc.id

  bgp {
    asn = var.router_asn
  }
}

# ========================================
# Cloud NAT 리소스
# ========================================
resource "google_compute_router_nat" "nat" {
  count  = var.enable_nat ? 1 : 0
  name   = "${var.vpc_name}-nat"
  router = google_compute_router.router[0].name
  region = var.nat_region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = var.nat_log_enable
    filter = var.nat_log_filter
  }
}
