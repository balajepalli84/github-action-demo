output "new_app_compartment_ocid" {
  description = "OCID of the newly created new-app compartment."
  value       = oci_identity_compartment.new_app.id
}
