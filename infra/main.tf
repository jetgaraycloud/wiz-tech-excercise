module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}

module "mongo_vm" {
  source = "./modules/mongo-vm"

  project_name           = var.project_name
  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.vpc.public_subnet_ids[0]
  ssh_allowed_cidr       = var.ssh_allowed_cidr
  k8s_subnet_cidrs       = var.private_subnet_cidrs
  key_pair_name          = var.key_pair_name
  instance_profile_name  = module.iam.mongo_vm_instance_profile_name
  instance_type          = var.mongo_vm_instance_type
}

module "eks_fargate" {
  source = "./modules/eks-fargate"

  project_name        = var.project_name
  cluster_version     = var.eks_cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
}
