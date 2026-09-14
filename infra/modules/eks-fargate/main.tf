resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = "${var.project_name}-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  # Control plane audit logging requirement (Cloud Native Security section)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_iam_role" "fargate_pod_execution" {
  name = "${var.project_name}-fargate-pod-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
      Condition = {
        ArnLike = {
          "aws:SourceArn" = "arn:aws:eks:*:*:fargateprofile/${var.project_name}-eks/*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  role       = aws_iam_role.fargate_pod_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# Pods only schedule onto Fargate if their namespace matches a selector here.
# Add a namespace before deploying into it.
resource "aws_eks_fargate_profile" "default" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "${var.project_name}-default"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn
  subnet_ids              = var.private_subnet_ids

  selector {
    namespace = "default"
  }

  selector {
    namespace = "kube-system"
  }

  selector {
    namespace = "todo-app"
  }
}

# OIDC provider for IRSA — required by the AWS Load Balancer Controller
# (and any other pod that needs to call AWS APIs) on a Fargate-only cluster.
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
