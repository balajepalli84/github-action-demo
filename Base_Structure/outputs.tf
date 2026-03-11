###############################################################################
# outputs.tf
###############################################################################

# --------------------------------------------------------------------------- #
# Compartments                                                                 #
# --------------------------------------------------------------------------- #

output "compartments" {
  description = "All provisioned compartments as a flat map keyed by logical name."
  value       = module.compartments.compartments
}

# --------------------------------------------------------------------------- #
# VCN                                                                         #
# --------------------------------------------------------------------------- #

output "vcn_id" {
  description = "OCID of the main VCN."
  value       = oci_core_vcn.main.id
}

output "vcn_cidr" {
  description = "CIDR block of the main VCN."
  value       = oci_core_vcn.main.cidr_blocks
}

# --------------------------------------------------------------------------- #
# Gateways                                                                     #
# --------------------------------------------------------------------------- #

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway."
  value       = oci_core_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway."
  value       = oci_core_nat_gateway.main.id
}

# --------------------------------------------------------------------------- #
# Subnets                                                                      #
# --------------------------------------------------------------------------- #

output "subnets" {
  description = <<-EOT
    All app/env subnets as a map keyed by "<app-key>-<env>".
    Each entry exposes: id, cidr_block, display_name, compartment_id.
  EOT
  value = {
    for k, s in oci_core_subnet.app_env : k => {
      id             = s.id
      cidr_block     = s.cidr_block
      display_name   = s.display_name
      compartment_id = s.compartment_id
    }
  }
}
output "apps_compartment_ocid" {
  description = "Apps compartment OCID"
  value       = module.compartments.compartments["APPS-CMP"].id
}

output "networking_compartment_ocid" {
  description = "Networking compartment OCID"
  value       = module.compartments.compartments["NETWORK-CMP"].id
}

output "vcn_ocid" {
  description = "Main VCN OCID"
  value       = oci_core_vcn.main.id
}

output "private_route_table_ocid" {
  description = "Private route table OCID"
  value       = oci_core_route_table.private_rt.id
}

output "security_list_ocid" {
  description = "Security list OCID"
  value       = oci_core_security_list.app_sl.id
}