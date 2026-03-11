###############################################################################
# compartments.auto.tfvars
#
# Compartment hierarchy
#
# Tenancy Root
# └── RBALAJEP-TEST-CMP  (rbalajep-test)
#     ├── NETWORKING-CMP  (centralized-networking)
#     ├── SECURITY-CMP    (security)
#     ├── OPS-CMP         (ops)
#     └── APPS-CMP        (apps)
#         ├── APP1-CMP    (app-1)
#         │   ├── APP1-NONPROD-CMP  (non-prod)
#         │   │   ├── APP1-DEV-CMP  (dev)
#         │   │   ├── APP1-UAT-CMP  (uat)
#         │   │   └── APP1-QA-CMP   (qa)
#         │   └── APP1-PROD-CMP     (prod)
#         └── APP2-CMP    (app-2)
#             ├── APP2-NONPROD-CMP  (non-prod)
#             │   ├── APP2-DEV-CMP  (dev)
#             │   ├── APP2-UAT-CMP  (uat)
#             │   └── APP2-QA-CMP   (qa)
#             └── APP2-PROD-CMP     (prod)
#
# Depth: 5 levels (OCI max is 6) — safe.
###############################################################################

compartments_configuration = {
  # rbalajep-test sits directly under the tenancy root.
  default_parent_id = "TENANCY-ROOT"

  # Set enable_delete = true ONLY when you want Terraform to physically
  # destroy a compartment on `terraform destroy` or when removed from config.
  enable_delete = false

  compartments = {

    ##########################################################################
    # RBALAJEP-TEST-CMP – sandbox/test wrapper (level 1)
    ##########################################################################
    "RBALAJEP-TEST-CMP" = {
      name        = "rbalajep-test"
      description = "Test compartment owned by rbalajep. Contains the full demo hierarchy."
      freeform_tags = {
        "compartment-type" = "test"
        "owner"            = "rbalajep"
      }

      children = {

        #----------------------------------------------------------------------
        # NETWORKING-CMP – centralised network services hub (level 2)
        #----------------------------------------------------------------------
        "NETWORKING-CMP" = {
          name        = "centralized-networking"
          description = "Centralised networking hub: VCNs, DRG, FastConnect, Service Gateway."
          freeform_tags = {
            "compartment-type" = "networking"
          }
        }

        #----------------------------------------------------------------------
        # SECURITY-CMP – security tooling and posture management (level 2)
        #----------------------------------------------------------------------
        "SECURITY-CMP" = {
          name        = "security"
          description = "Security services: Cloud Guard, Bastion, Vault, Security Zones."
          freeform_tags = {
            "compartment-type" = "security"
          }
        }

        #----------------------------------------------------------------------
        # OPS-CMP – operations / observability (level 2)
        #----------------------------------------------------------------------
        "OPS-CMP" = {
          name        = "ops"
          description = "Operational tooling: Logging, Monitoring, Events, Notifications."
          freeform_tags = {
            "compartment-type" = "ops"
          }
        }

        #----------------------------------------------------------------------
        # APPS-CMP – application workloads container (level 2)
        #----------------------------------------------------------------------
        "APPS-CMP" = {
          name        = "apps"
          description = "Parent compartment for all application workloads."
          freeform_tags = {
            "compartment-type" = "apps"
          }

          children = {

            #------------------------------------------------------------------
            # APP1-CMP – app-1 workload (level 3)
            #------------------------------------------------------------------
            "APP1-CMP" = {
              name        = "app-1"
              description = "Workload compartment for application 1."
              freeform_tags = {
                "app" = "app-1"
              }

              children = {

                # Non-production environments for app-1 (level 4)
                "APP1-NONPROD-CMP" = {
                  name        = "non-prod"
                  description = "Non-production umbrella for app-1 (dev, uat, qa)."
                  freeform_tags = {
                    "app"         = "app-1"
                    "environment" = "non-prod"
                  }

                  children = {

                    # Level 5
                    "APP1-DEV-CMP" = {
                      name        = "dev"
                      description = "Development environment for app-1."
                      freeform_tags = {
                        "app"         = "app-1"
                        "environment" = "dev"
                      }
                    }

                    "APP1-UAT-CMP" = {
                      name        = "uat"
                      description = "User-acceptance testing environment for app-1."
                      freeform_tags = {
                        "app"         = "app-1"
                        "environment" = "uat"
                      }
                    }

                    "APP1-QA-CMP" = {
                      name        = "qa"
                      description = "Quality-assurance environment for app-1."
                      freeform_tags = {
                        "app"         = "app-1"
                        "environment" = "qa"
                      }
                    }
                  }
                }

                # Production environment for app-1 (level 4)
                "APP1-PROD-CMP" = {
                  name        = "prod"
                  description = "Production environment for app-1."
                  freeform_tags = {
                    "app"         = "app-1"
                    "environment" = "prod"
                  }
                }
              }
            }

            #------------------------------------------------------------------
            # APP2-CMP – app-2 workload, mirrors app-1 (level 3)
            #------------------------------------------------------------------
            "APP2-CMP" = {
              name        = "app-2"
              description = "Workload compartment for application 2."
              freeform_tags = {
                "app" = "app-2"
              }

              children = {

                # Non-production environments for app-2 (level 4)
                "APP2-NONPROD-CMP" = {
                  name        = "non-prod"
                  description = "Non-production umbrella for app-2 (dev, uat, qa)."
                  freeform_tags = {
                    "app"         = "app-2"
                    "environment" = "non-prod"
                  }

                  children = {

                    # Level 5
                    "APP2-DEV-CMP" = {
                      name        = "dev"
                      description = "Development environment for app-2."
                      freeform_tags = {
                        "app"         = "app-2"
                        "environment" = "dev"
                      }
                    }

                    "APP2-UAT-CMP" = {
                      name        = "uat"
                      description = "User-acceptance testing environment for app-2."
                      freeform_tags = {
                        "app"         = "app-2"
                        "environment" = "uat"
                      }
                    }

                    "APP2-QA-CMP" = {
                      name        = "qa"
                      description = "Quality-assurance environment for app-2."
                      freeform_tags = {
                        "app"         = "app-2"
                        "environment" = "qa"
                      }
                    }
                  }
                }

                # Production environment for app-2 (level 4)
                "APP2-PROD-CMP" = {
                  name        = "prod"
                  description = "Production environment for app-2."
                  freeform_tags = {
                    "app"         = "app-2"
                    "environment" = "prod"
                  }
                }
              }
            }

          }
		"APP3-CMP" = {
              name        = "new-app"
              description = "Workload compartment for new-app."
              freeform_tags = {
                "app" = "new-app"
              }

              children = {

                "APP3-NONPROD-CMP" = {
                  name        = "non-prod"
                  description = "Non-production umbrella for new-app (dev, uat, qa)."
                  freeform_tags = {
                    "app"         = "new-app"
                    "environment" = "non-prod"
                  }

                  children = {

                    "APP3-DEV-CMP" = {
                      name        = "dev"
                      description = "Development environment for new-app."
                      freeform_tags = {
                        "app"         = "new-app"
                        "environment" = "dev"
                      }
                    }

                    "APP3-UAT-CMP" = {
                      name        = "uat"
                      description = "User-acceptance testing environment for new-app."
                      freeform_tags = {
                        "app"         = "new-app"
                        "environment" = "uat"
                      }
                    }

                    "APP3-QA-CMP" = {
                      name        = "qa"
                      description = "Quality-assurance environment for new-app."
                      freeform_tags = {
                        "app"         = "new-app"
                        "environment" = "qa"
                      }
                    }
                  }
                }
                "APP3-PROD-CMP" = {
                  name        = "prod"
                  description = "Production environment for new-app."
                  freeform_tags = {
                    "app"         = "new-app"
                    "environment" = "prod"
                  }
                }
              }
            }
        }

      }
    }

  }
}
