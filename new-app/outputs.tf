output "new_app_compartment_ocid" {
  value = oci_identity_compartment.new_app.id
}

output "new_app_dev_subnet_ocid" {
  value = oci_core_subnet.new_app_dev.id
}

output "new_app_uat_subnet_ocid" {
  value = oci_core_subnet.new_app_uat.id
}

output "new_app_qa_subnet_ocid" {
  value = oci_core_subnet.new_app_qa.id
}

output "new_app_prod_subnet_ocid" {
  value = oci_core_subnet.new_app_prod.id
}