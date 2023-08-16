output "default_execution_role" {
  value = aws_iam_role.sagemaker_domain_default_execution_role.arn
}
