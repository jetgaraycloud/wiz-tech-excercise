# CI/CD pipelines (next step)

Will contain two workflows:
- terraform-deploy.yml: plan/apply infra, gated by tfsec/Checkov scanning
- build-deploy-app.yml: build + push image to ECR, gated by Trivy/Grype scanning, then trigger K8s deploy

Plus branch protection rules on the repo (required PR review, no direct push to main).
