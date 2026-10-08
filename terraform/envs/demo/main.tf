module "hello_world_app" {
  source        = "../../modules/app"
  namespace     = var.namespace
  release_name  = var.release_name
  chart_path    = var.chart_path

  image_repository = var.image_repository
  image_tag        = var.image_tag
  replica_count    = var.replica_count

  env = var.env

  secret_env = {
    SECRET_FAVORITE_COLOR = var.secret_favorite_color
  }

  resources     = coalesce(var.resources, null)   # Overrides if exist on tfvars
  service_type  = var.service_type
  service_port  = var.service_port
}