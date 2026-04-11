# ========================================
# 개발 환경 방화벽 규칙
# ========================================
locals {
  dev_firewall_rules = merge(
    {
      allow_http = {
        name = "${var.vpc_name}-allow-http"
        allow = [
          {
            protocol = "tcp"
            ports    = ["80"]
          }
        ]
        source_ranges = ["0.0.0.0/0"]
        target_tags   = ["web-server"]
        priority      = 1000
      }
      allow_https = {
        name = "${var.vpc_name}-allow-https"
        allow = [
          {
            protocol = "tcp"
            ports    = ["443"]
          }
        ]
        source_ranges = ["0.0.0.0/0"]
        target_tags   = ["web-server"]
        priority      = 1000
      }
    },
    var.enable_iap_ssh ? {
      allow_iap_ssh = {
        name = "${var.vpc_name}-allow-iap-ssh"
        allow = [
          {
            protocol = "tcp"
            ports    = ["22"]
          }
        ]
        source_ranges = var.iap_ssh_source_ranges
        target_tags   = var.management_target_tags
        priority      = 1000
      }
    } : {},
    {
      allow_internal = {
        name = "${var.vpc_name}-allow-internal"
        allow = [
          {
            protocol = "tcp"
            ports    = ["0-65535"]
          },
          {
            protocol = "udp"
            ports    = ["0-65535"]
          },
          {
            protocol = "icmp"
          }
        ]
        source_ranges = ["10.0.0.0/16"]
        priority      = 65534
      }
    }
  )
}
