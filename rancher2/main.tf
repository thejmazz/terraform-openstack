provider "openstack" {
  version = "~> 1.5"
}

provider "template" {
  version = "~> 0.1"
}

data "openstack_compute_keypair_v2" "kp" {
  name = "${var.key_pair}"
}

data "template_file" "rancher_user_data" {
  template = "${file("${path.module}/files/rancher-server_userdata.yml")}"

  vars = {
    public_key = "${data.openstack_compute_keypair_v2.kp.public_key}"
  }
}

resource "openstack_compute_instance_v2" "rancher" {
  name = "rancher"
  image_name = "${var.image_name}"
  flavor_name = "m1.medium"

  user_data = "${data.template_file.rancher_user_data.rendered}"

  security_groups = [
    "default",
    "ssh_from_kidnet",
    "debug_all"
  ]

  config_drive = true

  network {
    name = "${var.network}"
  }
}

resource "openstack_networking_floatingip_v2" "rancher" {
  pool = "${var.floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "rancher" {
  floating_ip = "${openstack_networking_floatingip_v2.rancher.address}"
  instance_id = "${openstack_compute_instance_v2.rancher.id}"
  fixed_ip    = "${openstack_compute_instance_v2.rancher.network.0.fixed_ip_v4}"
}
