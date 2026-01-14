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
  description = "OCID of the compartment to deploy resources into (also used for Object Storage bucket creation)"
}

# New bucket name to CREATE
variable "new_bucket_name" {
  type        = string
  description = "Name of the new Object Storage bucket to create"
}

# Existing bucket name to READ (your current variable)
variable "bucket_name" {
  type        = string
  description = "Name of the existing Object Storage bucket to read"
}

variable "prefix" {
  type        = string
  description = "Optional object name prefix (acts like a folder path)"
  default     = ""
}
