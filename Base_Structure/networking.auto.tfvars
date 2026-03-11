###############################################################################
# networking.auto.tfvars
#
# VCN and per-app networking configuration.
#
# SCALING TO 120 APPS
# -------------------
# Add one line per additional app following the same pattern.
# The 'index' field MUST match the number used in compartments.auto.tfvars
# compartment keys (e.g. index=3 → compartment keys APP3-DEV-CMP, APP3-PROD-CMP …)
# It also drives the second CIDR octet:  10.<index>.<env_octet>.0/24
#
#   "app-3"   = { index = 3   }   →  10.3.x.x
#   "app-4"   = { index = 4   }   →  10.4.x.x
#   ...
#   "app-120" = { index = 120 }   →  10.120.x.x
###############################################################################

vcn_cidr         = "10.0.0.0/16"
vcn_display_name = "main-vcn"
vcn_dns_label    = "mainvcn"

apps = {
  "app-1" = { index = 1 }
  "app-2" = { index = 2 }

  # Uncomment and extend for more apps:
  # "app-3"   = { index = 3   }
  # "app-4"   = { index = 4   }
  # ...
  # "app-120" = { index = 120 }
}
