terraform {
  required_version = ">= 1.3.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0.0"
    }
  }

  # ---------------------------------------------------------------------------
  # Remote state – OCI Object Storage backend (recommended for GitHub Actions)
  # Uncomment and fill in before first `terraform init` in CI.
  # ---------------------------------------------------------------------------
  # backend "s3" {
  #   bucket                      = "tfstate-bucket"
  #   key                         = "new-app/terraform.tfstate"
  #   region                      = "us-ashburn-1"
  #   endpoint                    = "https://<namespace>.compat.objectstorage.us-ashburn-1.oraclecloud.com"
  #   access_key                  = "<customer-secret-key-id>"
  #   secret_key                  = "<customer-secret-key>"
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   force_path_style            = true
  # }
}

provider "oci" {
  region       = var.region
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
}
