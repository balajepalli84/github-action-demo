###############################################################################
# networking.tf
#
# Creates a centralised VCN in the networking compartment and one private
# subnet per application × environment.  Subnet CIDR scheme:
#
#   10.0.<(index-1)*4 + env_octet>.0/24
#
#   env_octet:  dev=0  uat=1  qa=2  prod=3
#
# Example (app-1, index=1):
#   dev  → 10.0.0.0/24  in APP1-DEV-CMP
#   uat  → 10.0.1.0/24  in APP1-UAT-CMP
#   qa   → 10.0.2.0/24  in APP1-QA-CMP
#   prod → 10.0.3.0/24  in APP1-PROD-CMP
#
# Example (app-2, index=2):
#   dev  → 10.0.4.0/24  in APP2-DEV-CMP
#   uat  → 10.0.5.0/24  in APP2-UAT-CMP
#   qa   → 10.0.6.0/24  in APP2-QA-CMP
#   prod → 10.0.7.0/24  in APP2-PROD-CMP
#
# Max supported apps with a /16 VCN and /24 subnets: 64 (256 third-octets / 4 envs).
#
# All subnets are PRIVATE (no public IPs).  Outbound internet egress goes
# via the NAT Gateway.  The Internet Gateway is present for any future
# public / bastion subnets.
###############################################################################

###############################################################################
# Locals – build a flat subnet map from var.apps × env_config
###############################################################################

locals {
  # Fixed environment definitions.
  # cmp_suffix must match the suffix used in compartments.auto.tfvars keys.
  env_config = {
    dev  = { octet = 0, cmp_suffix = "DEV-CMP"  }
    uat  = { octet = 1, cmp_suffix = "UAT-CMP"  }
    qa   = { octet = 2, cmp_suffix = "QA-CMP"   }
    prod = { octet = 3, cmp_suffix = "PROD-CMP" }
  }

  # Cross-product: app × env → one subnet entry each
  # Compartment key pattern: APP<index>-<ENV>-CMP  (e.g. APP1-DEV-CMP)
  subnet_list = flatten([
    for app_key, app in var.apps : [
      for env_name, env in local.env_config : {
        key             = "${app_key}-${env_name}"
        display_name    = "${app_key}-${env_name}-sn"
        cidr_block      = "10.0.${(app.index - 1) * 4 + env.octet}.0/24"
        dns_label       = "${replace(app_key, "-", "")}${env_name}"
        compartment_key = "APP${app.index}-${env.cmp_suffix}"
      }
    ]
  ])

  subnets = { for s in local.subnet_list : s.key => s }
}

###############################################################################
# VCN
###############################################################################

resource "oci_core_vcn" "main" {
  compartment_id = module.compartments.compartments["NETWORKING-CMP"].id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = var.vcn_display_name
  dns_label      = var.vcn_dns_label
}

###############################################################################
# Gateways
###############################################################################

resource "oci_core_internet_gateway" "main" {
  compartment_id = module.compartments.compartments["NETWORKING-CMP"].id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_display_name}-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "main" {
  compartment_id = module.compartments.compartments["NETWORKING-CMP"].id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_display_name}-ngw"
  block_traffic  = false
}

###############################################################################
# Route Tables
###############################################################################

# Public route table – for future bastion / jump-host subnets
resource "oci_core_route_table" "public" {
  compartment_id = module.compartments.compartments["NETWORKING-CMP"].id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_display_name}-public-rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# Private route table – used by all app/env subnets
resource "oci_core_route_table" "private" {
  compartment_id = module.compartments.compartments["NETWORKING-CMP"].id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_display_name}-private-rt"

  route_rules {
    network_entity_id = oci_core_nat_gateway.main.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

###############################################################################
# Security List (shared across all app/env subnets)
###############################################################################

resource "oci_core_security_list" "app_env" {
  compartment_id = module.compartments.compartments["NETWORKING-CMP"].id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.vcn_display_name}-app-sl"

  # Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }

  # Allow all TCP within the VCN CIDR (east-west)
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = var.vcn_cidr
    stateless = false
  }

  # Allow HTTPS from the internet
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow ICMP type 3 code 4 (path MTU discovery) from VCN
  ingress_security_rules {
    protocol  = "1" # ICMP
    source    = var.vcn_cidr
    stateless = false
    icmp_options {
      type = 3
      code = 4
    }
  }
}

###############################################################################
# Subnets – one per app × environment (private)
###############################################################################

resource "oci_core_subnet" "app_env" {
  for_each = local.subnets

  # Subnet lives in the matching app-env compartment (not networking)
  compartment_id = module.compartments.compartments[each.value.compartment_key].id
  vcn_id         = oci_core_vcn.main.id

  cidr_block   = each.value.cidr_block
  display_name = each.value.display_name
  dns_label    = each.value.dns_label

  # Private subnet – no public IPs assigned to VNICs
  prohibit_public_ip_on_vnic = true

  route_table_id    = oci_core_route_table.private.id
  security_list_ids = [oci_core_security_list.app_env.id]
}
