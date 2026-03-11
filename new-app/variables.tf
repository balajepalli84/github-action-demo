variable "region" {
  description = "OCI region"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "apps_compartment_ocid" {
  description = "Existing OCID of the apps compartment"
  type        = string
}

variable "vcn_ocid" {
  description = "Existing VCN OCID"
  type        = string
}

variable "private_route_table_ocid" {
  description = "Existing private route table OCID"
  type        = string
}

variable "security_list_ocid" {
  description = "Existing security list OCID"
  type        = string
}