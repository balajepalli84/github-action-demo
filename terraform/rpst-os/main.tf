provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  auth                = "securitytoken"
  config_file_profile = "DEFAULT"
}

# ------------------------------------------------
# Random suffix for bucket name
# ------------------------------------------------
resource "random_string" "bucket_suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# ------------------------------------------------
# CREATE bucket with DEFINED TAG
# ------------------------------------------------
resource "oci_objectstorage_bucket" "created" {
  compartment_id = var.compartment_ocid
  namespace      = "ociateam"
  name           = "${var.bucket_name_prefix}-${random_string.bucket_suffix.result}"

  access_type  = "NoPublicAccess"
  storage_tier = "Standard"

  # -------- Defined Tag --------
  defined_tags = {
    "Oracle-Standard.CostCenter" = "balajepalli84/github-action-demo"
  }
}

# ------------------------------------------------
# READ the SAME bucket using data source
# ------------------------------------------------
data "oci_objectstorage_bucket" "bucket" {
  namespace = "ociateam"
  name      = oci_objectstorage_bucket.created.name

  depends_on = [oci_objectstorage_bucket.created]
}

# ------------------------------------------------
# LIST objects
# ------------------------------------------------
data "oci_objectstorage_objects" "objs" {
  namespace = "ociateam"
  bucket    = data.oci_objectstorage_bucket.bucket.name
  prefix    = var.prefix
}

output "bucket_name" {
  value = data.oci_objectstorage_bucket.bucket.name
}

output "object_count" {
  value = length(data.oci_objectstorage_objects.objs.objects)
}

output "object_names" {
  value = [for o in data.oci_objectstorage_objects.objs.objects : o.name]
}
