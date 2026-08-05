output "project" {
  value = var.project_name
}

output "vpc_id" {
  description = "ID of the platform VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "Availability Zones used by the VPC"
  value       = module.vpc.availability_zones
}
output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "ecr_repository_url" {
  description = "URL used to push and pull Docker images"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}
output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = module.iam.github_actions_role_name
}

output "github_actions_role_arn" {
  description = "ARN used by GitHub Actions through OIDC"
  value       = module.iam.github_actions_role_arn
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider used by the workflow"
  value       = module.iam.github_oidc_provider_arn
}