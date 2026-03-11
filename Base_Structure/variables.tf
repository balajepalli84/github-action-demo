###############################################################################
# variables.tf
###############################################################################

# --------------------------------------------------------------------------- #
# Core identity                                                                #
# --------------------------------------------------------------------------- #

variable "tenancy_ocid" {
  description = "The OCID of the OCI tenancy."
  type        = string
}

variable "region" {
  description = "The OCI home region for IAM resources."
  type        = string
}

# --------------------------------------------------------------------------- #
# Compartments (IAM module)                                                   #
# --------------------------------------------------------------------------- #

variable "compartments_configuration" {
  description = "Compartment hierarchy configuration passed to the IAM module."
  type        = any
  default     = null
}

# --------------------------------------------------------------------------- #
# VCN                                                                         #
# --------------------------------------------------------------------------- #

variable "vcn_cidr" {
  description = "CIDR block for the main VCN. Must be large enough for all app subnets (10.0.0.0/16 covers up to 64 apps × 4 envs as /24 subnets)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_display_name" {
  description = "Display name for the VCN."
  type        = string
  default     = "main-vcn"
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN. Must be lowercase alphanumeric, max 15 chars."
  type        = string
  default     = "mainvcn"
}

# --------------------------------------------------------------------------- #
# Applications                                                                 #
# --------------------------------------------------------------------------- #

variable "apps" {
  description = <<-EOT
    Map of application definitions.

    Key   : application name (must match the name used in compartments.auto.tfvars,
            e.g. "app-1", "app-2").
    index : integer 1-120.  Drives two things:
              1. Second octet of every subnet CIDR → 10.<index>.<env>.0/24
              2. Compartment key lookup            → APP<index>-<ENV>-CMP

    IMPORTANT: 'index' must be consistent with the APP<N>-* compartment keys
    defined in compartments.auto.tfvars.
  EOT
  type = map(object({
    index = number
  }))
  default = {}
}
