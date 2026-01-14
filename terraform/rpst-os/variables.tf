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

variable "bucket_name_prefix" {
  type        = string
  description = "Prefix for the Object Storage bucket name"
}

variable "prefix" {
  type        = string
  description = "Optional object name prefix (acts like a folder path)"
  default     = ""
}
