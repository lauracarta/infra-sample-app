terraform {
  backend "s3" {
    bucket                  = "terraform-state-files"
    key                     = "applications/hello-world/demo/terraform.tfstate"
    region                  = "us-east-1"
    endpoint                = "http://localhost:4566"             # LocalStack
    use_lockfile            = true
    force_path_style        = true
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_requesting_account_id = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "docker-desktop"
  }
}