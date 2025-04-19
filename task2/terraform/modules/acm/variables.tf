variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
}

variable "private_key_path" {
  description = "Path to SSL private key file"
  type        = string
}

variable "certificate_path" {
  description = "Path to SSL certificate file"
  type        = string
}

variable "certificate_chain_path" {
  description = "Path to SSL certificate chain file"
  type        = string
} 