Owner: DevOps Team  
Last updated at: 09-29-2025

Need help? 
Reach out to our Slack channel! ✨ #devops-requests

# Application (Node.js)
Minimal Node.js service that always responds with **“Hello World!”**, built following production best practices:
- Node.js v20-alpine
- Express web server
- Health/readiness endpoints for Kubernetes probes
- The app listens for termination signals (SIGINT, SIGTERM) and performs a graceful shutdown by calling `server.close()`. This allows in-flight requests to complete before the container is terminated, avoiding dropped connections during rolling updates.
- Runs as non-root user to prevent privilege escalation attacks.

## Endpoints
- `/healthz` → liveness check (200 "ok")  
- `/readyz` → readiness check (200 "ready")  
- `/*` → returns "Hello World!"  

These endpoints ensure Kubernetes only routes traffic to healthy pods.

## Environment Variables
| Variable               | Description                     | Default       |
| ---------------------- | ------------------------------- | ------------- |
| `PORT`                 | Port where the server listens   | `3000`        |
| `APP_NAME`             | Service identifier              | `hello-world` |
| `SECRET_FAVORITE_COLOR`| Example secret (masked in logs) | `unknown`     |

In Kubernetes:
- Non-sensitive vars (`PORT`, `APP_NAME`) → stored in a **ConfigMap**
- Sensitive vars (`SECRET_FAVORITE_COLOR`) → stored in a **Secret**

## Dockerfile
The Dockerfile uses a **multi-stage build** for smaller and safer images:
- **Build stage**: install deps with `npm ci` (reproducible and lockfile-based)  
- **Runtime stage**: clean alpine base, `NODE_ENV=production`, run as non-root user, expose port 3000  

This ensures faster builds, minimal attack surface, and best practices.

## Running Locally
1.	Configure environment variables. Either export them manually or use an `.env` file duplicated from `.env.example`.
2. Run server.
```bash
# Run using direct command
npm start

# Or with Docker
make build-docker-image
docker run --rm -p 3000:3000 hello-world:latest
```

Access → http://localhost:3000  

# Helm Chart
Kubernetes manifests are **templatized with Helm**:  
- `templates/` → Deployments, Service, ConfigMap, Secret  
- `values.yaml` → defaults (replicas, ports, resources, env vars)  
- `Chart.yaml` → chart metadata  

**Variable Injection:** Terraform injects env-specific values (namespace, image tag, secrets, resources).  
This makes the app reusable across `stage`, `demo`, `prod` (and more!) without duplicating YAML.

**Zero-Downtime Deployments:** To prevent downtime during `terraform apply`, the Kubernetes Deployment uses a RollingUpdate strategy with `maxUnavailable: 0` and `maxSurge: 1`. This ensures a new pod becomes ready before terminating any old ones.


# Variables
| Variable                | Example    |
| ------------------------| -----------|
| `namespace`             | stage, demo, prod |
| `release_name`          | hello-world |
| `image_repository`      | hello-world |
| `image_tag`             | latest |
| `replica_count`         | 2 |
| `resources.requests`    | cpu=50m, memory=128Mi |
| `resources.limits`      | cpu=250m, memory=256Mi |
| `service_type`          | NodePort |
| `service_port`          | 3000 / 4000 / 5000 |
| `env.APP_NAME`          | hello-world |
| `env.PORT`              | 3000 |
| `secret_favorite_color` | CHANGE_ME |

# Terraform
Project is structured as:
- `terraform/envs/` → per-env configs (stage, demo, prod) to reduce blast radius  
- `terraform/modules/app` → Helm release definition 

- Remote state is stored in **S3 with locking enabled** to avoid concurrent updates. It's simulated locally with LocalStack.
To setup the S3 resources:

```bash
make localstack-up
make localstack-bootstrap-s3
```

# Makefile
To simplify repetitive commands, a Makefile is provided.  
It standardizes Docker builds, Terraform workflows, Kubernetes operations, and LocalStack setup.

Usage:  
```bash
make <target> ENV=<stage|demo|prod> [IMAGE_TAG=<tag>]
```

Complete list of commands can be viewed with:
```bash
make help
```

This ensures consistency across environments and fewer manual errors.

## Secret Management
Secrets are currently handled via Terraform, with sensitive variables encrypted in state. 
Future improvements could include:
- Securely inject secrets through CI/CD pipeline or ArgoCD
- Use external secret managers like AWS Secrets Manager or SSM Parameter Store

# Runbook
### Update existing environment
Build Docker image:
```bash
make build-docker-image
```
Deploy with Terraform:
```bash
make terraform-init ENV=<env>
make terraform-apply ENV=<env>
```

### Create new environment
1. Copy an existing `envs/<env>` folder  
2. Remove .terraform/ and state file.
3. Update `<env>.tfvars` (namespace, secrets, resources, ports)  
4. Update S3 key for new state file in <env>/provider.tf
5. Deploy with init + apply.
6. Update Makefile usage documentation to include the new environment.
7. Update the table below.

### Service Ports
| Env   | Port |
| ----- | ---- |
| stage | 3000 |
| demo  | 4000 |
| prod  | 5000 |

# Testing
```bash
# Local app
curl localhost:3000/healthz

# Helm validation
helm lint ./helm/hello-world
helm template ./helm/hello-world | kubeconform -

# Kubernetes rollout
kubectl -n stage rollout status deploy/hello-world
kubectl -n stage port-forward svc/hello-world 8080:3000
curl localhost:8080/readyz

# Terraform
terraform validate
terraform plan -var-file=stage.tfvars
```

✅ Criteria:  
- 2 pods running and ready  
- Probes return 200  
- No secrets showing up in logs  
- Terraform shows no changes on re-runs

# CI/CD (Future)
Automate in GithubActions (or similar CI/CD tool):  
    - Run unit tests on PRs and deployments
    - Docker build & scan
    - Helm lint + template validation  
    - Terraform validate + plan  
    - Deploy to an ephemeral Kubernetes cluster and validate:
1. Pods reach **Running** state with 2 replicas available
2. Readiness and Liveness probes succeed
2. Service endpoint responds 200 OK on expected port
4. Terraform state remains consistent (idempotent re-apply shows no drift)