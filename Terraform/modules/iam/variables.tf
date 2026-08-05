variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the IAM role"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the IAM role"
  type        = string
  default     = "main"
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository GitHub Actions can push to"
  type        = string
}

variable "create_github_oidc_provider" {
  description = "Whether this module should create the account-level GitHub OIDC provider"
  type        = bool
  default     = false
}