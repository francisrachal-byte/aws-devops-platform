module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}
module "iam" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  github_repository  = "francisrachal-byte/aws-devops-platform"
  github_branch      = "main"
  ecr_repository_arn = module.ecr.repository_arn

  create_github_oidc_provider = false
}