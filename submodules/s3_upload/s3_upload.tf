data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "auto_shutdown_bucket" {
  bucket = "sagemaker-auto-shutdown-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "auto_shutdown_bucket" {
  bucket = aws_s3_bucket.auto_shutdown_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_auto_shutdown" {
  bucket                  = aws_s3_bucket.auto_shutdown_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "auto_shutdown_bucket_life_cycle_config" {
  bucket = aws_s3_bucket.auto_shutdown_bucket.id

  rule {
    id = "life-cycle-configuration-rule"
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "auto_shutdown_bucket_access_log" {
  bucket = aws_s3_bucket.auto_shutdown_bucket.id

  target_bucket = aws_s3_bucket.auto_shutdown_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_versioning" "auto_shutdown_bucket_versioning" {
  bucket = aws_s3_bucket.auto_shutdown_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "autoshutdown_tar_upload" {
  bucket     = aws_s3_bucket.auto_shutdown_bucket.id
  key        = "sagemaker_studio_autoshutdown-0.1.5.tar.gz"
  source     = "${path.module}/../../assets/auto_shutdown_template/sagemaker_studio_autoshutdown-0.1.5.tar.gz"
  kms_key_id = var.kms_arn
}

