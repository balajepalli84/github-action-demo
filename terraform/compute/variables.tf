variable "region" {}
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "availability_domain" {}
variable "subnet_id" {}
variable "instance_name" {}
variable "shape" {}
variable "image_id" {}
variable "ocpus" {
  description = "Number of OCPUs for flexible shapes"
  type        = number
}

variable "memory_in_gbs" {
  description = "Amount of memory in GB for flexible shapes"
  type        = number
}
