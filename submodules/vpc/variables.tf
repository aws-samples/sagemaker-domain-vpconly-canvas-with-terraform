variable "cidr_block" {
  type        = string
  description = "CIDR block for SageMaker VPC"
  default     = "10.0.0.0/23"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.1.0/25", "10.0.1.128/25"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b"]
}
