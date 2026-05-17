data "terraform_remote_state" "lesson9" {
  backend = "s3"

  config = {
    bucket               = "terraform-state"
    key                  = "learning/09-remote-state/terraform.tfstate"
    region               = "us-east-1"
    endpoints            = { s3 = "http://192.168.0.151:30900" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
    workspace_key_prefix        = ""
    access_key = "terraform-user"
    secret_key = "TerraformState2024"
  }
}

resource "kubernetes_config_map_v1" "this" {
  metadata {
    name      = "consumer-config"
    namespace = data.terraform_remote_state.lesson9.outputs.namespace_name
  }

  data = {
    source_namespace = data.terraform_remote_state.lesson9.outputs.namespace_name
    source_uid       = data.terraform_remote_state.lesson9.outputs.namespace_uid
  }
}
