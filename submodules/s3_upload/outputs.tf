output "tar_file_id" {
  value = aws_s3_object.autoshutdown_tar_upload.id
}

output "tar_file_bucket" {
  value = aws_s3_bucket.auto_shutdown_bucket.id
}