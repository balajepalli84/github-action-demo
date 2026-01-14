provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  auth                = "securitytoken"
  config_file_profile = "DEFAULT"
}

# ------------------------------------------------------------
# Object Storage: create a new bucket, read it back, list objects
# ------------------------------------------------------------

# Get namespace automatically
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.tenancy_ocid
}

# Create a NEW bucket
resource "oci_objectstorage_bucket" "new_bucket" {
  compartment_id = var.bucket_compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = var.new_bucket_name

  # Optional but common settings (safe defaults)
  access_type  = "NoPublicAccess"
  storage_tier = "Standard"
}

# Read the bucket using a data source (as requested)
data "oci_objectstorage_bucket" "created_bucket" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  name      = oci_objectstorage_bucket.new_bucket.name

  # Ensure Terraform creates the bucket before reading it
  depends_on = [oci_objectstorage_bucket.new_bucket]
}

# List objects from the bucket (uses the data source bucket name)
data "oci_objectstorage_objects" "objs" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = data.oci_objectstorage_bucket.created_bucket.name
  prefix    = var.prefix
}

output "bucket_namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}

output "bucket_name" {
  value = data.oci_objectstorage_bucket.created_bucket.name
}

output "object_names" {
  value = [for o in data.oci_objectstorage_objects.objs.objects : o.name]
}

output "object_count" {
  value = length(data.oci_objectstorage_objects.objs.objects)
}

output "file_names_only" {
  value = [
    for o in data.oci_objectstorage_objects.objs.objects :
    element(reverse(split("/", o.name)), 0)
  ]
}
