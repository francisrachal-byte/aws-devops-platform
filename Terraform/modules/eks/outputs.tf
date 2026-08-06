output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data for the Kubernetes API server"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group created by EKS for the cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS control plane"
  value       = aws_iam_role.cluster.arn
}

output "node_group_name" {
  description = "Name of the EKS managed node group"
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  description = "ARN of the EKS managed node group"
  value       = aws_eks_node_group.this.arn
}

output "node_group_status" {
  description = "Current status of the EKS managed node group"
  value       = aws_eks_node_group.this.status
}

output "node_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS worker nodes"
  value       = aws_iam_role.nodes.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group containing EKS control-plane logs"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "kubectl_update_kubeconfig_command" {
  description = "AWS CLI command used to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${data.aws_subnet.cluster[var.cluster_subnet_ids[0]].region} --name ${aws_eks_cluster.this.name}"
}