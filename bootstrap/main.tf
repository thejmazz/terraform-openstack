provider "openstack" {
  version = "~> 1.5"
}

// === NETWORK ===

module "network" {
  source = "github.com/thejmazz/terraform-openstack//network"

  name = "${var.network_name}"

  dns_nameservers = "${var.subnet_dns_nameservers}"

  subnets = [{
    name = "${var.subnet_name}"
    cidr = "${var.subnet_cidr}"
    gateway_ip = "${var.subnet_gateway_ip}"
    allocation_pools_start = "${var.subnet_allocation_pools_start}"
    allocation_pools_end = "${var.subnet_allocation_pools_end}"
  }]

  external_network_id = "${var.external_network_id}"
}

// === SECURITY GROUPS ===

resource "openstack_networking_secgroup_v2" "ssh" {
  name = "bootstrap_ssh"
  description = "TCP:22 from ${join(",", var.ssh_cidr_sources,)}"

  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "ssh_rule" {
  count = "${length(var.ssh_cidr_sources)}"
  security_group_id = "${openstack_networking_secgroup_v2.ssh.id}"

  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = "22"
  port_range_max = "22"
  remote_ip_prefix = "${element(var.ssh_cidr_sources, count.index)}"
}

// === IMAGE ===

resource "openstack_images_image_v2" "ubuntu" {
  name = "bootstrap_ubuntu_1604"
  image_source_url = "https://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
  container_format = "bare"
  disk_format = "qcow2"
  verify_checksum = true
}

// === KEY PAIR ===
resource "openstack_compute_keypair_v2" "bootstrap_key" {
  name       = "bootstrap_key"
  public_key = "${var.public_key}"
}

// === INSTANCE ===

resource "openstack_compute_instance_v2" "bootstrap" {
  name = "bootstrap"
  image_name = "${openstack_images_image_v2.ubuntu.name}"
  flavor_name = "${var.flavor}"
  key_pair = "${openstack_compute_keypair_v2.bootstrap_key.name}"

  /* user_data = "${data.template_file.cromwell_user_data.rendered}" */

  security_groups = [
    "default",
    "${openstack_networking_secgroup_v2.ssh.name}",
    "debug_all"
  ]

  network {
    uuid = "${module.network.id}"
  }
}

resource "openstack_networking_floatingip_v2" "bootstrap" {
  pool = "${var.external_network_name}"
}

resource "openstack_compute_floatingip_associate_v2" "bootstrap" {
  floating_ip = "${openstack_networking_floatingip_v2.bootstrap.address}"
  instance_id = "${openstack_compute_instance_v2.bootstrap.id}"
}
