data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "SageMaker VPC"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name = "vpc_flow_log_group"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name               = "vpc_flow_log_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "log_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "log_policy" {
  name   = "log_policy"
  role   = aws_iam_role.vpc_flow_log_role.id
  policy = data.aws_iam_policy_document.log_policy.json
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "SageMaker Private Subnet ${count.index + 1}"
  }
}

resource "aws_route_table" "private_subnets_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "SageMaker Private Subnet Route Table"
  }
}

resource "aws_route_table_association" "private_rt_associations" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private_subnets_rt.id
}

resource "aws_security_group" "sagemaker_sg" {
  name        = "sagemaker_sg"
  description = "Allow certain NFS and TCP inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "NFS traffic over TCP on port 2049 between the domain and EFS volume"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "TCP traffic between JupyterServer app and the KernelGateway apps"
    from_port   = 8192
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "SageMaker sg"
  }
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc_endpoint_sg"
  description = "Allow incoming connections on port 443 from VPC"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow incoming connections on port 443 from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "VPC endpoint sg"
  }
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = toset([
    "com.amazonaws.${data.aws_region.current.name}.sagemaker.api",
    "com.amazonaws.${data.aws_region.current.name}.sagemaker.runtime",
    "com.amazonaws.${data.aws_region.current.name}.sagemaker.featurestore-runtime",
    "com.amazonaws.${data.aws_region.current.name}.servicecatalog"
  ])

  vpc_id              = aws_vpc.vpc.id
  service_name        = each.key
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id
  ]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "s3_vpce_route_table_association" {
  route_table_id  = aws_route_table.private_subnets_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# VPC endpoints for Canvas
resource "aws_vpc_endpoint" "interface_endpoints_canvas" {
  for_each = toset([
    "com.amazonaws.${data.aws_region.current.name}.forecast",
    "com.amazonaws.${data.aws_region.current.name}.forecastquery",
    "com.amazonaws.${data.aws_region.current.name}.rekognition",
    "com.amazonaws.${data.aws_region.current.name}.textract",
    "com.amazonaws.${data.aws_region.current.name}.comprehend",
    "com.amazonaws.${data.aws_region.current.name}.sts",
    "com.amazonaws.${data.aws_region.current.name}.redshift-data",
    "com.amazonaws.${data.aws_region.current.name}.athena",
    "com.amazonaws.${data.aws_region.current.name}.glue"
  ])

  vpc_id              = aws_vpc.vpc.id
  service_name        = each.key
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint_sg.id
  ]
}
