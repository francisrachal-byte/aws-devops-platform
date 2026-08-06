variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}
variable "enable_eks" {
  description = "Whether to create the EKS cluster and managed node group"
  type        = bool
  default     = false
}

variable "eks_public_access_cidrs" {
  description = "CIDR ranges allowed to access the public EKS API endpoint"
  type        = list(string)
  default     = []
}