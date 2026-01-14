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
  description = "Name of the Object Storage bucket to create (and then read via data source)"
}

variable "prefix" {
  type        = string
  description = "Optional object name prefix (acts like a folder path)"
  default     = ""
}
