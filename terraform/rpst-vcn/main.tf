provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  auth                = "securitytoken"
  config_file_profile = "DEFAULT"
}

resource "oci_core_virtual_network" "my_tf_vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = var.compartment_ocid
  display_name   = var.vcn_display_name
}

data "oci_core_vcn" "my_tf_vcn_read" {
  vcn_id = oci_core_virtual_network.my_tf_vcn.id
}

output "vcn_read_state" {
  value = data.oci_core_vcn.my_tf_vcn_read.state
}

output "vcn_read_cidr_blocks" {
  value = data.oci_core_vcn.my_tf_vcn_read.cidr_blocks
}

output "vcn_read_dns_label" {
  value = data.oci_core_vcn.my_tf_vcn_read.dns_label
}
