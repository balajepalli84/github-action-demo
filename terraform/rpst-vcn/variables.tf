variable "region" {
  type        = string
  description = "OCI region"
}

variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID"
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment to deploy resources into"
}

variable "vcn_display_name" {
  type        = string
  description = "Display name of the VCN"
}

variable "vcn_cidr_block" {
  type        = string
  description = "CIDR block for the VCN"
}
