# ========================================
# IAP SSH 접근 모듈
# ========================================
module "iap_access" {
  source = "../../modules/iap-access"

  project_id = var.project_id

  enable_iap_ssh        = var.enable_iap_ssh
  iap_ssh_members       = var.iap_ssh_members
  iap_ssh_admin_members = var.iap_ssh_admin_members
  service_account_email = var.service_account_email
}
