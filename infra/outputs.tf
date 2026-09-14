output "mongo_vm_public_ip" {
  description = "Public IP of the Mongo VM (SSH here to inspect/troubleshoot)"
  value       = module.mongo_vm.public_ip
}

output "backup_bucket_name" {
  description = "Public S3 bucket receiving daily Mongo backups"
  value       = module.mongo_vm.backup_bucket_name
}

output "eks_cluster_name" {
  description = "EKS cluster name — use with 'aws eks update-kubeconfig'"
  value       = module.eks_fargate.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks_fargate.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "Needed when wiring up IRSA for the AWS Load Balancer Controller"
  value       = module.eks_fargate.oidc_provider_arn
}
