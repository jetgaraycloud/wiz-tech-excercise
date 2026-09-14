# Wiz Technical Exercise (Junior TAM) — AWS / EKS Fargate

This repo builds the environment required by the Wiz Technical Exercise v4:
a two-tier app (containerized front end + outdated MongoDB on a VM), deployed
with intentional misconfigurations, plus CI/CD and native cloud security
controls on top.

## Repo layout

```
.
├── infra/                  Terraform: VPC, Mongo VM, IAM, EKS Fargate
│   ├── main.tf              Root module wiring everything together
│   ├── variables.tf         Root-level inputs
│   ├── outputs.tf           Root-level outputs (VM IP, cluster name, etc.)
│   ├── versions.tf          Provider/backend config
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/              Public subnet (Mongo VM) + private subnets (EKS)
│       ├── iam/               Over-permissive IAM role for the Mongo VM (intentional misconfig)
│       ├── mongo-vm/          EC2 instance, outdated AMI, SG rules, S3 backup bucket, user-data script
│       └── eks-fargate/       EKS cluster (Fargate profile, OIDC/IRSA, control plane logging)
├── k8s/                    Kubernetes manifests (Deployment, Service, Ingress, ClusterRoleBinding)
├── app/                    Containerized app source + Dockerfile (wizexercise.txt baked in)
├── .github/workflows/      CI/CD pipelines (IaC deploy, build/push/deploy)
└── docs/                   Presentation deck, notes, evidence/screenshots for the demo
```

## Status

- [x] Terraform module structure scaffolded (this commit)
- [ ] `k8s/` manifests (Deployment, Service, Ingress w/ ALB IP-target-mode, ClusterRoleBinding)
- [ ] `app/` Dockerfile + sample todo app with `wizexercise.txt`
- [ ] `.github/workflows/` IaC pipeline + build/deploy pipeline, with tfsec/Trivy scanning gates
- [ ] CloudTrail, GuardDuty (EKS Protection), one preventative control (AWS Config rule or SCP)
- [ ] Slide deck in Wiz template

## Cost management (personal AWS account)

This build is not free-tier-only. The two unavoidable hourly costs are the
EKS control plane (~$0.10/hr) and the NAT Gateway (~$0.045/hr + data
processing), roughly **$3.50/day combined just for these existing**, on top
of a small EC2 charge for the Mongo VM (`t3.small` by default, override with
`mongo_vm_instance_type` in your `.tfvars` if you want to try `t3.micro` for
free-tier coverage).

To keep spend minimal:
- Set an AWS Budget alert **before** your first `terraform apply`.
- Run `terraform destroy` at the end of a work session whenever you won't be
  back within the same day, especially across multi-day gaps. Recreating
  costs you ~10-15 minutes (mostly EKS cluster creation) but avoids paying
  for idle infrastructure.
- Leaving it running overnight between two same-week work sessions is fine
  (a few dollars), destroying and recreating daily isn't worth the time cost
  for that small a saving.
- **Destroy everything for good once the exercise is finished** (evening of
  Sept 22 at the latest). Nothing should be left running after the panel.

## Prerequisites before `terraform apply`

1. An AWS CLI profile configured against the CloudLabs-provisioned account.
2. An existing EC2 key pair in the target region (`key_pair_name` variable) — used for
   SSH access to the Mongo VM. Import or create one before applying.
3. Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars` and fill in your values.

## Usage

```bash
cd infra
terraform init
terraform plan -out plan.tfout
terraform apply plan.tfout
```

## Known intentional misconfigurations (per exercise spec)

These are deliberate, called for by the exercise, and should be called out
explicitly in the presentation, not "fixed":

- Mongo VM: outdated Ubuntu AMI, SSH open to `0.0.0.0/0`, IAM role with `ec2:*`
- MongoDB: outdated 4.4 release line, but auth enabled and network-restricted to K8s subnets
- S3 backup bucket: public read + public list
- Kubernetes: app's service account bound to `cluster-admin`

## Notes on EKS Fargate

- Pods only schedule onto Fargate if their namespace matches a Fargate
  Profile selector — see `todo-app`, `default`, and `kube-system` selectors
  in `modules/eks-fargate/main.tf`. Add a namespace to the profile before
  deploying anything into it.
- The AWS Load Balancer Controller must run in **IP target mode**
  (`alb.ingress.kubernetes.io/target-type: ip`) since there's no EC2 instance
  to register as a target. This gets wired up in `k8s/ingress.yaml` (next step).
- IRSA (IAM Roles for Service Accounts) requires the OIDC provider created in
  `modules/eks-fargate/main.tf` — the Load Balancer Controller's IAM role will
  attach to that.
