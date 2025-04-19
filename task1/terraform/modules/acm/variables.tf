variable "domain_name" {
  description = "Domain name for the certificate"
  type        = string
  default     = "akshat.cloud"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "production"
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "certificate_path" {
  description = "Path to the certificate file"
  type        = string
}

variable "certificate_chain_path" {
  description = "Path to the certificate chain file"
  type        = string
}

variable "tags" {
  description = "Additional tags for the certificate"
  type        = map(string)
  default     = {}
} 