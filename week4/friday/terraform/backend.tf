terraform {
  backend "s3" {
    bucket         = "kijanikiosk-terraform-state"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    # Use the updated syntax to fix the warning
    endpoints = {
      s3 = "http://localhost:4566"
    }
    force_path_style            = true 
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true # Add this to fix the Error
    skip_s3_checksum            = true
  }
}
