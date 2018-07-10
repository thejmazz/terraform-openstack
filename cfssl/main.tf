provider "openstack" {
  version = "~> 1.5"
}

provider "template" {
  version = "~> 0.1"
}

data "openstack_networking_network_v2" "network" {
  name = "candig_lan"
}

data "openstack_compute_keypair_v2" "kp" {
  name = "${var.key_pair}"
}

data "template_file" "rootca_user_data" {
  template = "${file("${path.module}/files/rootca_ignition.yml")}"

  vars = {
    public_key = "${data.openstack_compute_keypair_v2.kp.public_key}"

    ca_common_name = "CanDIG Toronto Node CA"
    country = "Canada"
    city = "Toronto"
    organization = "HSC"
    organization_unit = "CCM"
    state = "Ontario"
  }
}

data "ct_config" "coreos_user_data" {
  content = "${data.template_file.rootca_user_data.rendered}"
  platform = "openstack-metadata"
}

resource "openstack_compute_instance_v2" "rootca" {
  name = "cfssl-ca"
  image_name = "CoreOS Stable 1745.7.0"
  /* image_name = "Ubuntu 16.04" */
  flavor_name = "m1.small"

  user_data = "${data.ct_config.coreos_user_data.rendered}"

  security_groups = [
    "default",
    "ssh_from_kidnet",
    /* "debug_all" */
  ]

  /* config_drive = true */

  network {
    /* name = "${var.network}" */
    uuid = "${data.openstack_networking_network_v2.network.id}"
  }
}
