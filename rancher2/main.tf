provider "openstack" {
  version = "~> 1.5"
}

provider "template" {
  version = "~> 0.1"
}

resource "openstack_images_image_v2" "rancheros" {
  name = "RancherOS 1.3.0"
  image_source_url = "https://github.com/rancher/os/releases/download/v1.3.0/rancheros-openstack.img"
  container_format = "bare"
  disk_format = "qcow2"
  min_disk_gb = "1"
  min_ram_mb = "512"
  protected = "false"
}

data "openstack_compute_keypair_v2" "kp" {
  name = "candig_dev_key"
}

data "template_file" "rancher_user_data" {
  template = "${file("${path.module}/files/rancher-server_userdata.yml")}"

  vars = {
    public_key = "${data.openstack_compute_keypair_v2.kp.public_key}"
  }
}

resource "openstack_compute_instance_v2" "rancher" {
  name = "rancher"
  image_id = "${openstack_images_image_v2.rancheros.id}"
  flavor_name = "m1.medium"

  user_data = "${data.template_file.rancher_user_data.rendered}"

  security_groups = [
    "default",
    "ssh_from_kidnet",
    "DEBUG_ALL"
  ]

  config_drive = "true"

  network {
    name = "CanDIG_Lan1"
  }
}

resource "openstack_networking_floatingip_v2" "rancher" {
  pool = "${var.floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "myip" {
  floating_ip = "${openstack_networking_floatingip_v2.rancher.address}"
  instance_id = "${openstack_compute_instance_v2.rancher.id}"
  fixed_ip    = "${openstack_compute_instance_v2.rancher.network.0.fixed_ip_v4}"
}
