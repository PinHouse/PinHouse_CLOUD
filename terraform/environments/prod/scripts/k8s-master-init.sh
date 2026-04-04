#!/usr/bin/env bash
set -euxo pipefail

# ========================================
# 기본 환경 점검
# ========================================
if [ "$(id -u)" -ne 0 ]; then
  echo "이 스크립트는 root 권한으로 실행해야 합니다."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ========================================
# Ubuntu 기본 패키지 업데이트
# ========================================
apt-get update -y
apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl gpg containerd

# ========================================
# swap 비활성화
# ========================================
swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# ========================================
# Kubernetes 네트워크용 커널 모듈 및 sysctl 설정
# ========================================
mkdir -p /etc/modules-load.d /etc/sysctl.d /etc/apt/keyrings /etc/containerd

cat <<'EOF' >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<'EOF' >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# ========================================
# containerd 설정
# ========================================
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl daemon-reload
systemctl enable --now containerd

# ========================================
# Kubernetes apt 저장소 설정
# ========================================
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' >/etc/apt/sources.list.d/kubernetes.list

# ========================================
# Kubernetes 패키지 설치
# ========================================
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# ========================================
# 서비스 활성화
# ========================================
systemctl enable --now kubelet

# ========================================
# 후속 작업 안내
# ========================================
echo "마스터 노드 초기 설정이 완료되었습니다. 이후 kubeadm init 및 CNI 설치를 진행하세요."
