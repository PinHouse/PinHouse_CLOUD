# ========================================
# IAP 접근 공통 로컬 값
# ========================================
locals {
  iap_access_members           = setunion(toset(var.iap_ssh_members), toset(var.iap_ssh_admin_members))
  service_account_user_members = local.iap_access_members
}

# ========================================
# IAP 및 OS Login API 활성화
# ========================================
resource "google_project_service" "iap_api" {
  count = var.enable_iap_ssh ? 1 : 0

  project = var.project_id
  service = "iap.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "oslogin_api" {
  count = var.enable_iap_ssh ? 1 : 0

  project = var.project_id
  service = "oslogin.googleapis.com"

  disable_on_destroy = false
}

# ========================================
# IAP SSH 프로젝트 IAM 권한
# ========================================
resource "google_project_iam_member" "iap_tunnel_resource_accessor" {
  for_each = var.enable_iap_ssh ? local.iap_access_members : toset([])

  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = each.value

  depends_on = [google_project_service.iap_api]
}

resource "google_project_iam_member" "os_login" {
  for_each = var.enable_iap_ssh ? toset(var.iap_ssh_members) : toset([])

  project = var.project_id
  role    = "roles/compute.osLogin"
  member  = each.value

  depends_on = [google_project_service.oslogin_api]
}

resource "google_project_iam_member" "os_admin_login" {
  for_each = var.enable_iap_ssh ? toset(var.iap_ssh_admin_members) : toset([])

  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = each.value

  depends_on = [google_project_service.oslogin_api]
}

# ========================================
# 서비스 계정 위임 권한
# ========================================
resource "google_service_account_iam_member" "service_account_user" {
  for_each = var.enable_iap_ssh && var.service_account_email != null ? local.service_account_user_members : toset([])

  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
