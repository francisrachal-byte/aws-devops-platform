variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev, staging, or production"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will run"
  type        = string
}

variable "cluster_subnet_ids" {
  description = "Subnet IDs used by the EKS control plane"
  type        = list(string)

  validation {
    condition     = length(var.cluster_subnet_ids) >= 2
    error_message = "The EKS cluster requires at least two subnets."
  }
}

variable "node_subnet_ids" {
  description = "Subnet IDs where the EKS managed worker nodes will run"
  type        = list(string)

  validation {
    condition     = length(var.node_subnet_ids) >= 2
    error_message = "The managed node group requires at least two subnets."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version used by the EKS cluster"
  type        = string
  default     = "1.36"

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.kubernetes_version))
    error_message = "The Kubernetes version must use a format such as 1.36."
  }
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API endpoint is accessible publicly"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the Kubernetes API endpoint is accessible inside the VPC"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR ranges permitted to reach the public Kubernetes API endpoint"
  type        = list(string)

  validation {
    condition     = length(var.public_access_cidrs) > 0
    error_message = "At least one public access CIDR must be provided."
  }
}

variable "enabled_cluster_log_types" {
  description = "EKS control-plane logs sent to CloudWatch Logs"
  type        = list(string)

  default = [
    "api",
    "audit",
    "authenticator"
  ]

  validation {
    condition = length(
      setsubtract(
        toset(var.enabled_cluster_log_types),
        toset([
          "api",
          "audit",
          "authenticator",
          "controllerManager",
          "scheduler"
        ])
      )
    ) == 0

    error_message = "Unsupported EKS control-plane log type provided."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed node group"
  type        = list(string)

  default = [
    "t3.small"
  ]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "At least one EC2 instance type must be provided."
  }
}

variable "node_ami_type" {
  description = "EKS-optimized AMI type used by the managed nodes"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_capacity_type" {
  description = "EC2 capacity type used by the managed node group"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition = contains(
      [
        "ON_DEMAND",
        "SPOT"
      ],
      var.node_capacity_type
    )

    error_message = "The node capacity type must be ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  description = "Root EBS volume size for each worker node in GiB"
  type        = number
  default     = 20

  validation {
    condition     = var.node_disk_size >= 20
    error_message = "The node disk size must be at least 20 GiB."
  }
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "The desired node count must be at least one."
  }
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 1
    error_message = "The minimum node count must be at least one."
  }
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.node_max_size >= 1
    error_message = "The maximum node count must be at least one."
  }
}

variable "node_max_unavailable" {
  description = "Maximum number of nodes unavailable during an update"
  type        = number
  default     = 1

  validation {
    condition     = var.node_max_unavailable >= 1
    error_message = "At least one node must be allowed to become unavailable during an update."
  }
}

variable "node_labels" {
  description = "Kubernetes labels assigned to the managed worker nodes"
  type        = map(string)

  default = {
    workload = "platform-pulse"
  }
}

variable "tags" {
  description = "Additional tags applied to EKS resources"
  type        = map(string)
  default     = {}
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