###############################################################################
# new-app compartment
#
# Creates a single child compartment called "new-app" directly under the
# level-1 compartment (rbalajep-test).
#
# Hierarchy after apply:
#   Tenancy Root
#   └── rbalajep-test          ← var.parent_compartment_ocid
#       └── new-app            ← created here
###############################################################################

resource "oci_identity_compartment" "new_app" {
  compartment_id = var.parent_compartment_ocid
  name           = "new-app"
  description    = "Compartment for the new-app workload under rbalajep-test."
  enable_delete  = false

  freeform_tags = {
    "compartment-type" = "app"
    "app"              = "new-app"
    "managed-by"       = "terraform"
  }
}
