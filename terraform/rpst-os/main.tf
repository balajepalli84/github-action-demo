provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  auth                = "securitytoken"
  config_file_profile = "rpst"
}

# --- Object Storage: read a bucket and list object names ---

# Get namespace automatically
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.tenancy_ocid
}

# Read existing bucket
data "oci_objectstorage_bucket" "bucket" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  name      = var.bucket_name
}

# List objects
data "oci_objectstorage_objects" "objs" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = data.oci_objectstorage_bucket.bucket.name
  prefix    = var.prefix
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
