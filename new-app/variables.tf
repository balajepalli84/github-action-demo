###############################################################################
# variables.tf – new-app compartment
###############################################################################

# ---------------------------------------------------------------------------
# OCI authentication  (injected as TF_VAR_* secrets in GitHub Actions)
# ---------------------------------------------------------------------------

variable "tenancy_ocid" {
  description = "OCID of the OCI tenancy."
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user running Terraform."
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API key associated with user_ocid."
  type        = string
}

variable "private_key" {
  description = "PEM-encoded private key content (the full key, not a file path)."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI home region."
  type        = string
}

# ---------------------------------------------------------------------------
# Compartment placement
# ---------------------------------------------------------------------------

variable "parent_compartment_ocid" {
  description = "OCID of the level-1 compartment (rbalajep-test) that will own new-app."
  type        = string
}
