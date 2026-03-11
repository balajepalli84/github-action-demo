###############################################################################
# terraform.tfvars – non-sensitive defaults
#
# All sensitive values (tenancy_ocid, user_ocid, fingerprint, private_key,
# parent_compartment_ocid) are supplied by GitHub Actions as TF_VAR_* secrets.
# Do NOT commit secrets to this file.
###############################################################################

region = "us-ashburn-1"
