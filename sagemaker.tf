data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "sagemaker_efs_kms_key" {
  description = "KMS key used to encrypt SageMaker Studio EFS volume"
  enable_key_rotation = true
}

resource "aws_kms_key_policy" "example" {
  key_id = aws_kms_key.sagemaker_efs_kms_key.id
  policy = jsonencode({
    Id = "example"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = [data.aws_caller_identity.current.account_id]
        }

        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

module "sagemaker_domain_execution_role" {
  source  = "./submodules/iam"
  kms_arn = aws_kms_key.sagemaker_efs_kms_key.arn
}

module "sagemaker_domain_vpc" {
  source               = "./submodules/vpc"
  cidr_block           = local.vpc.cidr_block
  private_subnet_cidrs = local.vpc.private_subnet_cidrs
  azs                  = local.vpc.availability_zones
}

module "auto_shutdown_s3_upload" {
  source  = "./submodules/s3_upload"
  kms_arn = aws_kms_key.sagemaker_efs_kms_key.arn
}

resource "aws_sagemaker_studio_lifecycle_config" "auto_shutdown" {
  studio_lifecycle_config_name     = "auto-shutdown"
  studio_lifecycle_config_app_type = "JupyterServer"
  studio_lifecycle_config_content  = base64encode(templatefile("${path.module}/assets/auto_shutdown_template/autoshutdown-script.sh", { tar_file_bucket = module.auto_shutdown_s3_upload.tar_file_bucket, tar_file_id = module.auto_shutdown_s3_upload.tar_file_id }))
}

resource "aws_sagemaker_domain" "sagemaker_domain" {
  domain_name = var.domain_name
  auth_mode   = var.auth_mode
  vpc_id      = module.sagemaker_domain_vpc.vpc_id
  subnet_ids  = module.sagemaker_domain_vpc.subnet_ids

  default_user_settings {
    execution_role = module.sagemaker_domain_execution_role.default_execution_role
    jupyter_server_app_settings {
      default_resource_spec {
        lifecycle_config_arn = aws_sagemaker_studio_lifecycle_config.auto_shutdown.arn
        sagemaker_image_arn = local.sagemaker_image_arn
      }
      lifecycle_config_arns = [aws_sagemaker_studio_lifecycle_config.auto_shutdown.arn]
    }

    canvas_app_settings {
      time_series_forecasting_settings {
        status = "ENABLED"
      }
    }
  }

  domain_settings {
    security_group_ids = [module.sagemaker_domain_vpc.security_group_id]
  }

  kms_key_id = aws_kms_key.sagemaker_efs_kms_key.arn

  app_network_access_type = var.app_network_access_type

  retention_policy {
    home_efs_file_system = var.efs_retention_policy
  }
}

resource "aws_sagemaker_user_profile" "default_user" {
  domain_id         = aws_sagemaker_domain.sagemaker_domain.id
  user_profile_name = "defaultuser"

  user_settings {
    execution_role  = module.sagemaker_domain_execution_role.default_execution_role
    security_groups = [module.sagemaker_domain_vpc.security_group_id]
  }
}
