# OpenStack Provider Variables
variable "auth_url" {
  description = "OpenStack authentication URL"
  type        = string
}

variable "project_id" {
  description = "OpenStack project ID"
  type        = string
}

variable "project_name" {
  description = "OpenStack project name"
  type        = string
}

variable "user_domain_name" {
  description = "OpenStack user domain name"
  type        = string
  default     = "Default"
}

variable "project_domain_id" {
  description = "OpenStack project domain ID"
  type        = string
  default     = "default"
}

variable "username" {
  description = "OpenStack username"
  type        = string
}

variable "password" {
  description = "OpenStack password"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OpenStack region"
  type        = string
  default     = "regionOne"
}

variable "interface" {
  description = "OpenStack interface type"
  type        = string
  default     = "public"
}

variable "identity_api_version" {
  description = "OpenStack Identity API version"
  type        = string
  default     = "3"
}
