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
module "eks" {
  count = var.enable_eks ? 1 : 0

  source = "../../modules/eks"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.vpc.vpc_id

  cluster_subnet_ids = module.vpc.private_subnet_ids
  node_subnet_ids    = module.vpc.public_subnet_ids

  public_access_cidrs = var.eks_public_access_cidrs

  node_instance_types = [
    "t3.small"
  ]

  node_capacity_type = "ON_DEMAND"

  node_desired_size = 1
  node_min_size     = 1
  node_max_size     = 2

  node_labels = {
    workload    = "platform-pulse"
    environment = var.environment
  }

  tags = {
    Application = "platform-pulse"
  }
}