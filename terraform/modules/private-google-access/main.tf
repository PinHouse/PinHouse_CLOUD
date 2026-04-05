# ========================================
# Private Google Access 로컬 변수
# ========================================
locals {
  google_api_vip_ipv4_addresses = var.google_api_domain_option == "private.googleapis.com" ? [
    "199.36.153.8",
    "199.36.153.9",
    "199.36.153.10",
    "199.36.153.11"
    ] : [
    "199.36.153.4",
    "199.36.153.5",
    "199.36.153.6",
    "199.36.153.7"
  ]

  google_api_vip_cidr = var.google_api_domain_option == "private.googleapis.com" ? "199.36.153.8/30" : "199.36.153.4/30"
}

# ========================================
# Cloud DNS API 리소스
# ========================================
resource "google_project_service" "dns_api" {
  project            = var.project_id
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}

# ========================================
# googleapis.com Private DNS 리소스
# ========================================
resource "google_dns_managed_zone" "googleapis_private_zone" {
  project     = var.project_id
  name        = "${var.name_prefix}-googleapis"
  dns_name    = "googleapis.com."
  description = "Private Google Access용 googleapis.com private zone입니다."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network_self_link
    }
  }

  depends_on = [google_project_service.dns_api]
}

resource "google_dns_record_set" "google_api_domain_a" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis_private_zone.name
  name         = "${var.google_api_domain_option}."
  type         = "A"
  ttl          = 300
  rrdatas      = local.google_api_vip_ipv4_addresses
}

resource "google_dns_record_set" "googleapis_wildcard_cname" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis_private_zone.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["${var.google_api_domain_option}."]
}

# ========================================
# pkg.dev Private DNS 리소스
# ========================================
resource "google_dns_managed_zone" "pkg_dev_private_zone" {
  project     = var.project_id
  name        = "${var.name_prefix}-pkg-dev"
  dns_name    = "pkg.dev."
  description = "Artifact Registry용 pkg.dev private zone입니다."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network_self_link
    }
  }

  depends_on = [google_project_service.dns_api]
}

resource "google_dns_record_set" "pkg_dev_a" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.pkg_dev_private_zone.name
  name         = "pkg.dev."
  type         = "A"
  ttl          = 300
  rrdatas      = local.google_api_vip_ipv4_addresses
}

resource "google_dns_record_set" "pkg_dev_wildcard_cname" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.pkg_dev_private_zone.name
  name         = "*.pkg.dev."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["pkg.dev."]
}

# ========================================
# Google API 라우트 리소스
# ========================================
resource "google_compute_route" "google_api_vip_route" {
  name             = "${var.name_prefix}-google-api-vip"
  project          = var.project_id
  network          = var.network_self_link
  dest_range       = local.google_api_vip_cidr
  priority         = var.route_priority
  next_hop_gateway = "default-internet-gateway"
  tags             = length(var.route_tags) > 0 ? var.route_tags : null
}

resource "google_compute_route" "google_api_direct_connectivity_route" {
  count = var.create_direct_connectivity_route ? 1 : 0

  name             = "${var.name_prefix}-google-api-direct"
  project          = var.project_id
  network          = var.network_self_link
  dest_range       = "34.126.0.0/18"
  priority         = var.route_priority
  next_hop_gateway = "default-internet-gateway"
  tags             = length(var.route_tags) > 0 ? var.route_tags : null
}
