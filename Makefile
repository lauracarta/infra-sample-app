# ====== Settings ======
SHELL := /bin/bash

# --- Require environment for Kubernetes and Terraform commands ---
ifneq (,$(filter terraform-% kubernetes-%,$(MAKECMDGOALS))) # If not equal to these commands
ifndef ENV # If ENV is not defined yet
$(error ENV is not set. Usage: make <target> ENV=<stage|demo|prod> [IMAGE_TAG=<tag>])
endif
endif

APPLICATION_NAME := hello-world
NAMESPACE        := $(ENV)
HELM_CHART_PATH  := ./helm/hello-world
DOCKER_IMAGE     := $(APPLICATION_NAME)$:$(IMAGE_TAG)

# Kubernetes
KUBERNETES_CONTEXT ?= $(shell kubectl config current-context)

# Terraform
TERRAFORM_ENV_DIR  := terraform/envs/$(ENV)
TERRAFORM_VARS     := $(ENV).tfvars

# LocalStack (optional backend for tfstate)
AWS_ENDPOINT       := http://localhost:4566
TERRAFORM_BUCKET   := terraform-state-files
TERRAFORM_KEY      := applications/hello-world/$(ENV)/terraform.tfstate

.PHONY: help
help:
	@echo ""
	@echo "Usage: make <target> ENV=<stage|demo|prod> [IMAGE_TAG=<tag>]"
	@echo ""
	@echo "Targets:"
	@echo "  build-docker-image             - docker build application image ($(DOCKER_IMAGE))"
	@echo "  terraform-init                 - run terraform init in $(TERRAFORM_ENV_DIR)"
	@echo "  terraform-apply                - run terraform apply"
	@echo "  terraform-refresh              - run terraform refresh"
	@echo "  terraform-destroy              - run terraform destroy"
	@echo "  show-kube-context              - show current Kubernetes context"
	@echo "  kubernetes-get-status      - get pods and services in namespace $(NAMESPACE)"
	@echo "  kubernetes-port-forward        - port-forward service/$(APPLICATION_NAME) 8080:3000"
	@echo "  kubernetes-logs                - follow logs from deployment/$(APPLICATION_NAME)"
	@echo "  localstack-up                  - run LocalStack (to simulate S3 lock behavior) on port 4566"
	@echo "  localstack-bootstrap-s3        - create S3 bucket for Terraform state"
	@echo "  localstack-list-tfstate        - list Terraform state objects in S3"
	@echo "  terraform-force-unlock ID=<id> - force-unlock Terraform state by lock id"
	@echo ""

# ---------- Utilities ----------
.PHONY: show-kubernetes-context
show-kube-context:
	@echo "Kubernetes context: $(KUBERNETES_CONTEXT)"
	@kubectl config get-contexts

# ---------- Docker ----------
.PHONY: build-docker-image
build-docker-image:
	docker build -t $(DOCKER_IMAGE) -f app/Dockerfile app/

# ---------- Terraform ----------
.PHONY: terraform-init terraform-apply terraform-refresh terraform-destroy
terraform-init:
	@test -f "$(TERRAFORM_ENV_DIR)/$(TERRAFORM_VARS)" || (echo ">>> Missing $(TERRAFORM_ENV_DIR)/$(TERRAFORM_VARS). Copy the .example and fill values."; exit 1)
	cd $(TERRAFORM_ENV_DIR) && terraform init

terraform-apply:
	@test -f "$(TERRAFORM_ENV_DIR)/$(TERRAFORM_VARS)" || (echo ">>> Missing $(TERRAFORM_ENV_DIR)/$(TERRAFORM_VARS). Copy the .example and fill values."; exit 1)
	@if [ -n "$(IMAGE_TAG)" ]; then \
	  echo ">>> Applying with image_tag=$(IMAGE_TAG)"; \
	  cd $(TERRAFORM_ENV_DIR) && terraform apply -var-file=$(TERRAFORM_VARS) -var="image_tag=$(IMAGE_TAG)"; \
	else \
	  cd $(TERRAFORM_ENV_DIR) && terraform apply -var-file=$(TERRAFORM_VARS); \
	fi

terraform-refresh:
	@test -f "$(TERRAFORM_ENV_DIR)/$(TERRAFORM_VARS)" || true
	cd $(TERRAFORM_ENV_DIR) && terraform refresh -var-file=$(TERRAFORM_VARS)


terraform-destroy:
	@test -f "$(TERRAFORM_ENV_DIR)/$(TERRAFORM_VARS)" || true
	cd $(TERRAFORM_ENV_DIR) && terraform destroy -var-file=$(TERRAFORM_VARS)

# ---------- Kubernetes ----------
.PHONY: kubernetes-get-status kubernetes-port-forward kubernetes-logs
kubernetes-get-status:
	kubectl get pods -n $(NAMESPACE)
	kubectl get svc  -n $(NAMESPACE)

kubernetes-port-forward:
	kubectl -n $(NAMESPACE) port-forward svc/$(APPLICATION_NAME) 8080:3000

kubernetes-logs:
	kubectl -n $(NAMESPACE) logs -f deploy/$(APPLICATION_NAME)

# ---------- LocalStack ----------
.PHONY: localstack-up localstack-bootstrap-s3 localstack-list-tfstate terraform-force-unlock localstack-down localstack-restart
localstack-up:
	docker rm -f localstack 2>/dev/null || true
	docker run --rm -d --name localstack -p 4566:4566 -e SERVICES="s3" localstack/localstack
	@echo ""
	@echo "Export fake AWS creds in this shell:"
	@echo '  export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1'
	@echo ""

localstack-bootstrap-s3:
	aws --endpoint-url=$(AWS_ENDPOINT) s3 mb s3://$(TERRAFORM_BUCKET) || true
	aws --endpoint-url=$(AWS_ENDPOINT) s3 ls

localstack-list-tfstate:
	@if [ -z "$(ENV)" ]; then \
	  echo "ENV is not set. Usage: make $@ ENV=<stage|demo|prod>"; exit 1; \
	fi
	aws --endpoint-url=$(AWS_ENDPOINT) s3 ls s3://$(TERRAFORM_BUCKET)/applications/hello-world/$(ENV)/ || true

terraform-force-unlock:
	@if [ -z "$$ID" ]; then echo "Usage: make terraform-force-unlock ENV=$(ENV) ID=<lock-id-from-error>"; exit 1; fi
	cd $(TERRAFORM_ENV_DIR) && terraform force-unlock -force $$ID

localstack-down:
	@echo "Stopping LocalStack..."
	-docker stop localstack 2>/dev/null || true
	-docker rm -f localstack 2>/dev/null || true

localstack-restart: 
	@echo "Restarting LocalStack..."
	$(MAKE)localstack-down 
	@sleep 2
	$(MAKE) localstack-up