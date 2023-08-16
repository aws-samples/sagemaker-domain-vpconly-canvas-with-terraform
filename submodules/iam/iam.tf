data "aws_iam_policy" "AmazonSageMakerFullAccess" {
  name = "AmazonSageMakerFullAccess"
}

data "aws_iam_policy" "AmazonSageMakerCanvasFullAccess" {
  name = "AmazonSageMakerCanvasFullAccess"
}

data "aws_iam_policy" "AmazonSageMakerCanvasAIServicesAccess" {
  name = "AmazonSageMakerCanvasAIServicesAccess"
}

data "aws_iam_policy_document" "sagemaker_domain_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com", "forecast.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "sagemaker_kms" {
  name        = "sagemaker_kms_policy"
  path        = "/"
  description = "KMS policy for SageMaker"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Effect = "Allow"
        Resource = [
          var.kms_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "sagemaker_domain_default_execution_role" {
  name               = "sagemaker_domain_exec_role_default"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_domain_assume_role_policy.json

  managed_policy_arns = [
    data.aws_iam_policy.AmazonSageMakerFullAccess.arn,
    data.aws_iam_policy.AmazonSageMakerCanvasFullAccess.arn,
    data.aws_iam_policy.AmazonSageMakerCanvasAIServicesAccess.arn,
    aws_iam_policy.sagemaker_kms.arn
  ]
}
