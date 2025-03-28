provider "oci" {
  region               = var.region
  tenancy_ocid         = var.tenancy_ocid
  auth                 = "securitytoken"
  config_file_profile  = "upst"
}

resource "oci_core_instance" "my_tf_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_name
  shape               = var.shape
  metadata = { test_key = timestamp() }

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  create_vnic_details {
    subnet_id = var.subnet_id
  }
}
