// === NETWORK ===

resource "openstack_networking_network_v2" "net" {
  name = "${var.name}"
  admin_state_up = "${var.admin_state_up}"
}

// === SUBNETS ===

resource "openstack_networking_subnet_v2" "subnets" {
  count = "${length(var.subnets)}"

  network_id = "${openstack_networking_network_v2.net.id}"

  name = "${lookup(var.subnets[count.index], "name", "subnet-${count.index + 1}")}"
  cidr = "${lookup(var.subnets[count.index], "cidr", "192.168.${count.index + 1}.0/24")}"
  gateway_ip = "${lookup(var.subnets[count.index], "gateway_ip", "192.168.${count.index + 1}.1")}"
  allocation_pools = {
    start = "${lookup(var.subnets[count.index], "allocation_pools_start", "192.168.${count.index + 1}.2")}"
    end = "${lookup(var.subnets[count.index], "allocation_pools_stop", "192.168.${count.index + 1}.254")}"
  }
  dns_nameservers = "${var.dns_nameservers}"
  ip_version = "${lookup(var.subnets[count.index], "ip_version", "4")}"
  enable_dhcp = "${lookup(var.subnets[count.index], "enable_dhcp", true)}"
}

// === ROUTER ===

resource "openstack_networking_router_v2" "router" {
  name = "${var.name}_router"
  admin_state_up  = true
  external_network_id = "${var.external_network_id}"
}

// === ROUTER ASSOCIATIONS ===

// TODO control over this instead of each subnet

resource "openstack_networking_router_interface_v2" "demo_router_interface_1" {
  count = "${length(var.subnets)}"
  router_id = "${openstack_networking_router_v2.router.id}"


  subnet_id = "${element(openstack_networking_subnet_v2.subnets.*.id, count.index)}"
}
