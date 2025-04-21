# backend can be used to store the state file in a remote location
# terraform init -backend-config=backend.tf
# terraform plan -var-file=terraform.tfvars
# terraform apply -var-file=terraform.tfvars
# terraform destroy -var-file=terraform.tfvars

# terraform {
#   backend "s3" {
#     bucket = "terraform-state-bucket"
#     key    = "terraform.tfstate"
#     region = "us-west-2"
#   }
# }