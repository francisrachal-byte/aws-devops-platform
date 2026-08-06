locals {
  cluster_name    = "${var.project_name}-${var.environment}"
  node_group_name = "${var.project_name}-${var.environment}-nodes"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -------------------------------------------------------------------
# Subnet validation data
# -------------------------------------------------------------------

data "aws_subnet" "cluster" {
  for_each = toset(var.cluster_subnet_ids)

  id = each.value
}

data "aws_subnet" "nodes" {
  for_each = toset(var.node_subnet_ids)

  id = each.value
}

# -------------------------------------------------------------------
# EKS cluster IAM role
# -------------------------------------------------------------------

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    sid    = "AllowEKSAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "eks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-cluster-role"

  description = "IAM role used by the ${local.cluster_name} EKS control plane"

  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${local.cluster_name}-cluster-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role = aws_iam_role.cluster.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# -------------------------------------------------------------------
# EKS node IAM role
# -------------------------------------------------------------------

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    sid    = "AllowEC2AssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "nodes" {
  name = "${local.cluster_name}-node-role"

  description = "IAM role used by the ${local.cluster_name} EKS worker nodes"

  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${local.cluster_name}-node-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role = aws_iam_role.nodes.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_pull_policy" {
  role = aws_iam_role.nodes.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# The VPC CNI requires AWS permissions to manage pod networking.
#
# For the first version of this project, the policy is attached directly
# to the node role. Later, we can move it to a dedicated Kubernetes
# service-account role using EKS Pod Identity or IRSA.
resource "aws_iam_role_policy_attachment" "cni_policy" {
  role = aws_iam_role.nodes.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# -------------------------------------------------------------------
# CloudWatch control-plane logs
# -------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cluster" {
  name = "/aws/eks/${local.cluster_name}/cluster"

  retention_in_days = 7

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${local.cluster_name}-control-plane-logs"
    }
  )
}

# -------------------------------------------------------------------
# EKS control plane
# -------------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  name = local.cluster_name

  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = var.enabled_cluster_log_types

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"

    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = var.cluster_subnet_ids

    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access

    public_access_cidrs = var.public_access_cidrs
  }

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = local.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.cluster
  ]

  lifecycle {
    precondition {
      condition = alltrue([
        for subnet in data.aws_subnet.cluster :
        subnet.vpc_id == var.vpc_id
      ])

      error_message = "Every EKS control-plane subnet must belong to the supplied VPC."
    }

    precondition {
      condition = length(
        toset([
          for subnet in data.aws_subnet.cluster :
          subnet.availability_zone
        ])
      ) >= 2

      error_message = "The EKS control plane requires subnets in at least two Availability Zones."
    }
  }
}

# -------------------------------------------------------------------
# EKS managed node group
# -------------------------------------------------------------------

resource "aws_eks_node_group" "this" {
  cluster_name = aws_eks_cluster.this.name

  node_group_name = local.node_group_name
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.node_subnet_ids

  version = var.kubernetes_version

  ami_type       = var.node_ami_type
  capacity_type  = var.node_capacity_type
  disk_size      = var.node_disk_size
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = var.node_max_unavailable
  }

  labels = var.node_labels

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = local.node_group_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.ecr_pull_policy,
    aws_iam_role_policy_attachment.cni_policy
  ]

  lifecycle {
    precondition {
      condition = alltrue([
        for subnet in data.aws_subnet.nodes :
        subnet.vpc_id == var.vpc_id
      ])

      error_message = "Every worker-node subnet must belong to the supplied VPC."
    }

    precondition {
      condition = length(
        toset([
          for subnet in data.aws_subnet.nodes :
          subnet.availability_zone
        ])
      ) >= 2

      error_message = "The managed node group requires subnets in at least two Availability Zones."
    }

    precondition {
      condition = (
        var.node_min_size <= var.node_desired_size &&
        var.node_desired_size <= var.node_max_size
      )

      error_message = "Node scaling must satisfy min_size <= desired_size <= max_size."
    }
  }
}