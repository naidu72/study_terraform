# Local backend for development
# State stored in ./terraform.tfstate
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
