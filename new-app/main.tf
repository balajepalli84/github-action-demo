resource "oci_identity_compartment" "new_app" {
  compartment_id = var.apps_compartment_ocid
  name           = "new-app"
  description    = "Workload compartment for new-app."
  enable_delete  = false

  freeform_tags = {
    app = "new-app"
  }
}

resource "oci_identity_compartment" "new_app_nonprod" {
  compartment_id = oci_identity_compartment.new_app.id
  name           = "non-prod"
  description    = "Non-production umbrella for new-app."
  enable_delete  = false

  freeform_tags = {
    app         = "new-app"
    environment = "non-prod"
  }
}

resource "oci_identity_compartment" "new_app_dev" {
  compartment_id = oci_identity_compartment.new_app_nonprod.id
  name           = "dev"
  description    = "Development environment for new-app."
  enable_delete  = false

  freeform_tags = {
    app         = "new-app"
    environment = "dev"
  }
}

resource "oci_identity_compartment" "new_app_uat" {
  compartment_id = oci_identity_compartment.new_app_nonprod.id
  name           = "uat"
  description    = "User acceptance testing environment for new-app."
  enable_delete  = false

  freeform_tags = {
    app         = "new-app"
    environment = "uat"
  }
}

resource "oci_identity_compartment" "new_app_qa" {
  compartment_id = oci_identity_compartment.new_app_nonprod.id
  name           = "qa"
  description    = "Quality assurance environment for new-app."
  enable_delete  = false

  freeform_tags = {
    app         = "new-app"
    environment = "qa"
  }
}

resource "oci_identity_compartment" "new_app_prod" {
  compartment_id = oci_identity_compartment.new_app.id
  name           = "prod"
  description    = "Production environment for new-app."
  enable_delete  = false

  freeform_tags = {
    app         = "new-app"
    environment = "prod"
  }
}

resource "oci_core_subnet" "new_app_dev" {
  compartment_id = oci_identity_compartment.new_app_dev.id
  vcn_id         = var.vcn_ocid

  cidr_block   = "10.0.8.0/24"
  display_name = "new-app-dev-sn"
  dns_label    = "newappdev"

  prohibit_public_ip_on_vnic = true
  route_table_id             = var.private_route_table_ocid
  security_list_ids          = [var.security_list_ocid]
}

resource "oci_core_subnet" "new_app_uat" {
  compartment_id = oci_identity_compartment.new_app_uat.id
  vcn_id         = var.vcn_ocid

  cidr_block   = "10.0.9.0/24"
  display_name = "new-app-uat-sn"
  dns_label    = "newappuat"

  prohibit_public_ip_on_vnic = true
  route_table_id             = var.private_route_table_ocid
  security_list_ids          = [var.security_list_ocid]
}

resource "oci_core_subnet" "new_app_qa" {
  compartment_id = oci_identity_compartment.new_app_qa.id
  vcn_id         = var.vcn_ocid

  cidr_block   = "10.0.10.0/24"
  display_name = "new-app-qa-sn"
  dns_label    = "newappqa"

  prohibit_public_ip_on_vnic = true
  route_table_id             = var.private_route_table_ocid
  security_list_ids          = [var.security_list_ocid]
}

resource "oci_core_subnet" "new_app_prod" {
  compartment_id = oci_identity_compartment.new_app_prod.id
  vcn_id         = var.vcn_ocid

  cidr_block   = "10.0.11.0/24"
  display_name = "new-app-prod-sn"
  dns_label    = "newappprod"

  prohibit_public_ip_on_vnic = true
  route_table_id             = var.private_route_table_ocid
  security_list_ids          = [var.security_list_ocid]
}