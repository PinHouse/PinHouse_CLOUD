# ========================================
# 버킷 출력값
# ========================================
output "buckets" {
  description = "생성된 버킷 정보입니다."
  value = {
    for k, v in google_storage_bucket.buckets : k => {
      name          = v.name
      url           = v.url
      self_link     = v.self_link
      location      = v.location
      storage_class = v.storage_class
    }
  }
}

output "bucket_names" {
  description = "생성된 버킷 이름 목록입니다."
  value       = { for k, v in google_storage_bucket.buckets : k => v.name }
}

output "bucket_urls" {
  description = "생성된 버킷 URL 목록입니다."
  value       = { for k, v in google_storage_bucket.buckets : k => v.url }
}

# ========================================
# 버킷 객체 출력값
# ========================================
output "bucket_objects" {
  description = "생성된 버킷 객체 정보입니다."
  value = {
    for k, v in google_storage_bucket_object.objects : k => {
      name         = v.name
      bucket       = v.bucket
      media_link   = v.media_link
      self_link    = v.self_link
      content_type = v.content_type
    }
  }
}

# ========================================
# 버킷 알림 출력값
# ========================================
output "bucket_notifications" {
  description = "생성된 버킷 알림 정보입니다."
  value = {
    for k, v in google_storage_notification.notifications : k => {
      id              = v.id
      notification_id = v.notification_id
      self_link       = v.self_link
    }
  }
}
