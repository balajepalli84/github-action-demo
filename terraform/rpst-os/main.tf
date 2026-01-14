provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  auth                = "securitytoken"
  config_file_profile = "DEFAULT"
}

# -----------------------------
# Namespace
# -----------------------------
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.tenancy_ocid
}

# -----------------------------
# 1) CREATE bucket
# -----------------------------
resource "oci_objectstorage_bucket" "created" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = var.bucket_name

  access_type  = "NoPublicAccess"
  storage_tier = "Standard"
}

# -----------------------------
# 2) READ the same bucket using data source
# -----------------------------
data "oci_objectstorage_bucket" "bucket" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  name      = oci_objectstorage_bucket.created.name

  depends_on = [oci_objectstorage_bucket.created]
}

# -----------------------------
# 3) LIST objects from the bucket
# -----------------------------
data "oci_objectstorage_objects" "objs" {
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = data.oci_objectstorage_bucket.bucket.name
  prefix    = var.prefix
}

output "bucket_namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}

output "bucket_name" {
  value = data.oci_objectstorage_bucket.bucket.name
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
