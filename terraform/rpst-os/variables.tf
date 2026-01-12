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

variable "bucket_name" {
  type        = string
  description = "Name of the existing Object Storage bucket to read"
}

variable "prefix" {
  type        = string
  description = "Optional object name prefix (acts like a folder path)"
  default     = ""
}
