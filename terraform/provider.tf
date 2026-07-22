terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}

# OpenStack provider configuration using variables from terraform.tfvars
provider "openstack" {
  auth_url            = var.auth_url
  user_name           = var.username
  password            = var.password
  tenant_name         = var.project_name
  tenant_id           = var.project_id
  user_domain_name    = var.user_domain_name
  project_domain_id   = var.project_domain_id
  region              = var.region
  endpoint_type       = var.interface
}
