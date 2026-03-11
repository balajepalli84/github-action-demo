###############################################################################
# McGraw Demo – Compartment Design
# Uses: github.com/oci-landing-zones/terraform-oci-modules-iam//compartments
###############################################################################

module "compartments" {
  source = "github.com/oci-landing-zones/terraform-oci-modules-iam//compartments?ref=v0.3.3"

  tenancy_ocid               = var.tenancy_ocid
  compartments_configuration = var.compartments_configuration
}
