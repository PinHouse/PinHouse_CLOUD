# ========================================
# 프로덕션 방화벽 값
# ========================================
locals {
  prod_firewall_rules = merge(
    {
      # 워커 노드가 외부 HTTP 트래픽을 받을 수 있도록 허용합니다.
      allow_http = {
        name = "${var.vpc_name}-allow-http"
        allow = [
          {
            protocol = "tcp"
            ports    = ["80"]
          }
        ]
        source_ranges = ["0.0.0.0/0"]
        target_tags   = ["k8s-worker"]
        priority      = 1000
      }

      # 워커 노드가 외부 HTTPS 트래픽을 받을 수 있도록 허용합니다.
      allow_https = {
        name = "${var.vpc_name}-allow-https"
        allow = [
          {
            protocol = "tcp"
            ports    = ["443"]
          }
        ]
        source_ranges = ["0.0.0.0/0"]
        target_tags   = ["k8s-worker"]
        priority      = 1000
      }

      # 마스터와 워커 노드가 Kubernetes API 서버에 접근할 수 있도록 허용합니다.
      allow_k8s_api_from_nodes = {
        name = "${var.vpc_name}-allow-k8s-api-from-nodes"
        allow = [
          {
            protocol = "tcp"
            ports    = ["6443"]
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-master"]
        priority    = 1000
      }

      # 마스터 노드 간 etcd와 컨트롤 플레인 포트를 허용합니다.
      allow_k8s_control_plane = {
        name = "${var.vpc_name}-allow-k8s-control-plane"
        allow = [
          {
            protocol = "tcp"
            ports    = ["2379-2380", "10250", "10257", "10259"]
          }
        ]
        source_tags = ["k8s-master"]
        target_tags = ["k8s-master"]
        priority    = 1000
      }

      # 마스터 노드가 워커 노드 kubelet에 접근할 수 있도록 허용합니다.
      allow_kubelet_from_control_plane = {
        name = "${var.vpc_name}-allow-kubelet-from-control-plane"
        allow = [
          {
            protocol = "tcp"
            ports    = ["10250"]
          }
        ]
        source_tags = ["k8s-master"]
        target_tags = ["k8s-worker"]
        priority    = 1000
      }

      # 노드 간 kube-proxy 헬스 및 프록시 포트를 허용합니다.
      allow_kube_proxy_from_nodes = {
        name = "${var.vpc_name}-allow-kube-proxy-from-nodes"
        allow = [
          {
            protocol = "tcp"
            ports    = ["10256"]
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-worker"]
        priority    = 1000
      }

      # Calico BGP 피어링에 필요한 TCP 179 포트를 허용합니다.
      allow_calico_bgp = {
        name = "${var.vpc_name}-allow-calico-bgp"
        allow = [
          {
            protocol = "tcp"
            ports    = ["179"]
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-master", "k8s-worker"]
        priority    = 1000
      }

      # Calico IP-in-IP 터널링 트래픽을 허용합니다.
      allow_calico_ipip = {
        name = "${var.vpc_name}-allow-calico-ipip"
        allow = [
          {
            protocol = "ipip"
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-master", "k8s-worker"]
        priority    = 1000
      }

      # Pod CIDR 대역에서 노드로 들어오는 Calico 워크로드 트래픽을 허용합니다.
      allow_calico_pod_cidr = {
        name = "${var.vpc_name}-allow-calico-pod-cidr"
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
        source_ranges = [var.k8s_pod_cidr]
        target_tags   = ["k8s-master", "k8s-worker"]
        priority      = 1000
      }
    },
    var.enable_iap_ssh ? {
      # IAP TCP 터널을 통한 SSH 접근을 허용합니다.
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
      # Kubernetes 노드 태그를 가진 인스턴스끼리 내부 통신을 허용합니다.
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
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-master", "k8s-worker"]
        priority    = 65534
      }
    }
  )
}
