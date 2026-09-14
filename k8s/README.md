# Kubernetes manifests (next step)

Will contain:
- namespace.yaml (todo-app namespace, matching the Fargate profile selector)
- deployment.yaml (Mongo connection via env var, wizexercise.txt provable via kubectl exec)
- service.yaml
- ingress.yaml (ALB, target-type: ip, since there's no EC2 node to register)
- clusterrolebinding.yaml (binds the app's service account to cluster-admin — intentional misconfig)
- secret.yaml or external-secret reference for the Mongo connection string
