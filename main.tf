provider "oci" {
  tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaa3qmjxr43tjexx75r6gwk6vjw22ermohbw2vbxyhczksgjir7xdq"
  user_ocid        = "ocid1.user.oc1..aaaaaaaafaq7vh72xyy3gj47vooic6hi7a2w2tvkzplgcjlohe7aawa4n6ea"
  fingerprint      = "65:a4:ea:9a:6b:fc:60:70:10:88:35:9b:70:18:d4:f5"
  private_key_path = "~/.oci/key.pem"
  region           = "us-ashburn-1"
}

resource "oci_core_virtual_network" "my_tf_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = "ocid1.compartment.oc1..aaaaaaaafklcekq7wnwrt4zxeizcrmvhltz6wxaqzwksbhbs73yz6mtpi5za"
  display_name   = "my-vcn"
}
