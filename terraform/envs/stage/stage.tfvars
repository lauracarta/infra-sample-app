namespace        = "stage"
release_name     = "hello-world"

image_repository = "hello-world"
image_tag = "latest"

replica_count    = 2

resources = {
  requests = { cpu = "50m", memory = "128Mi" }
  limits   = { cpu = "128m", memory = "256Mi" }
}

service_type = "NodePort"
service_port = 5000

# Environment Variables
env = {
  APP_NAME = "hello-world"
  PORT     = "3000"
}

# Secrets
secret_favorite_color = "blue"