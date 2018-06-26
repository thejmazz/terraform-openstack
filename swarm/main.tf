provider "openstack" {
  version = "~> 1.5"
}

provider "external" {
  version = "~> 1.0"
}

provider "template" {
  version = "~> 0.1"
}

// DATA

data "openstack_compute_keypair_v2" "kp" {
  name = "${var.key_pair}"
}

# TODO separate, use snippets
data "template_file" "coreos_user_data" {
  template = "${file("${path.module}/files/coreos.yml")}"

  vars = {
    public_key = "${data.openstack_compute_keypair_v2.kp.public_key}"
  }
}

data "ct_config" "coreos_user_data" {
  content = "${data.template_file.coreos_user_data.rendered}"
  platform = "openstack-metadata"
}

data "external" "swarm_tokens" {
  program = [ "./scripts/fetch-tokens.sh" ]

  query = {
    host = "${openstack_networking_floatingip_v2.swarm-manager-01.address}"
  }

  /* depends_on = [ "openstack_compute_instance_v2.swarm-manager-01" ] */
  depends_on = [ "openstack_compute_floatingip_associate_v2.myip" ]
}

// RESOURCES

resource "openstack_compute_instance_v2" "swarm-manager-01" {
  name = "swarm-manager-01"
  image_name = "coreos_stable_1688.5.3"
  flavor_name = "m1.small"

  # Not actually required for CoreOS
  key_pair = "${var.key_pair}"

  user_data = "${data.ct_config.coreos_user_data.rendered}"

  security_groups = [
    "default",
    "ssh_from_kidnet",
    "DEBUG_ALL"
  ]

  network {
    name = "${var.network}"
  }

  connection {
    type = "ssh"
    user = "core"
    /* host = "${openstack_networking_floatingip_v2.swarm-manager-01.address}" */
    host = "${self.network.0.fixed_ip_v4}"
    bastion_host = "172.20.4.67"
    bastion_user = "core"
  }

  # self.network.0.fixed_ip_v4 could work as well
  # put this into cloudinit or ignition?
  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr $$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
    ]
  }
}

resource "openstack_networking_floatingip_v2" "swarm-manager-01" {
  pool = "${var.floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "myip" {
  floating_ip = "${openstack_networking_floatingip_v2.swarm-manager-01.address}"
  instance_id = "${openstack_compute_instance_v2.swarm-manager-01.id}"
  fixed_ip    = "${openstack_compute_instance_v2.swarm-manager-01.network.0.fixed_ip_v4}"
}

resource "openstack_compute_instance_v2" "swarm-managers" {
  count = "${var.manager_count - 1}"
  name = "swarm-manager-0${count.index + 2}"
  image_name = "coreos_stable_1688.5.3"
  flavor_name = "m1.small"

  key_pair = "${var.key_pair}"
  user_data = "${data.ct_config.coreos_user_data.rendered}"

  security_groups = [
    "default",
    "ssh_from_bastion"
  ]

  network {
    name = "${var.network}"
  }

  connection {
    type = "ssh"
    user = "core"
    bastion_host = "172.20.4.67"
    bastion_user = "core"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token ${data.external.swarm_tokens.result.manager} ${openstack_compute_instance_v2.swarm-manager-01.network.0.fixed_ip_v4}:2377"
    ]
  }
}

resource "openstack_compute_instance_v2" "swarm-workers" {
  count = "${var.worker_count}"
  name = "swarm-worker-0${count.index + 1}"
  image_name = "coreos_stable_1688.5.3"
  flavor_name = "m1.medium"

  key_pair = "${var.key_pair}"
  user_data = "${data.ct_config.coreos_user_data.rendered}"

  security_groups = [
    "default",
    "ssh_from_bastion"
  ]

  network {
    name = "${var.network}"
  }

  connection {
    type = "ssh"
    user = "core"
    bastion_host = "172.20.4.67"
    bastion_user = "core"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token ${data.external.swarm_tokens.result.worker} ${openstack_compute_instance_v2.swarm-manager-01.network.0.fixed_ip_v4}:2377"
    ]
  }
}
