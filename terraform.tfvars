env     = "dev"
project = "homelab"

services = {
  nginx = {
    image         = "nginx:stable"
    internal_port = 80
    external_port = 8080
    env_vars      = { NGINX_HOST = "homelab.dev.local" }
  }
  postgres = {
    image         = "postgres:15"
    internal_port = 5432
    external_port = 5432
    env_vars = {
      POSTGRES_DB       = "appdb"
      POSTGRES_USER     = "appuser"
      POSTGRES_PASSWORD = "devpassword"
    }
  }
  mockapi = {
    image         = "kennethreitz/httpbin"
    internal_port = 80
    external_port = 8081
  }
}
# To add a 4th service: just add another block here.
# No changes to any .tf file needed.