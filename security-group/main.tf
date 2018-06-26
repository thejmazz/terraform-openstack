provider "openstack" {
  version = "~> 1.5"
}

resource "openstack_networking_secgroup_v2" "sg" {
  name = "${var.name}"
  description = "${var.description}"
  delete_default_rules = "${var.delete_default_rules}"
  region = "${var.region}"
  tenant_id = "${var.tenant_id}"
}

// TODO handle self remote_group_id
// TODO handle multiple remote_ip_prefix's ?
// NOTE inline user-data?

resource "openstack_networking_secgroup_rule_v2" "rules" {
  /* count = "${var.create_vpc && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0}" */
  count = "${length(var.rules)}"
  security_group_id = "${openstack_networking_secgroup_v2.sg.id}"

  direction = "${lookup(var.rules[count.index], "direction", "${var.rule_default_direction}")}"
  ethertype = "${lookup(var.rules[count.index], "ethertype", "IPv4")}"
  protocol = "${lookup(var.rules[count.index], "protocol", "tcp")}"

  port_range_min = "${lookup(var.rules[count.index], "port", "")}"
  port_range_max = "${lookup(var.rules[count.index], "port", "")}"

  remote_ip_prefix = "${lookup(var.rules[count.index], "remote_ip_prefix", "")}"
  remote_group_id = "${lookup(var.rules[count.index], "remote_group_id", "")}"

  // Different from security group!?
  region = "${lookup(var.rules[count.index], "region", "${var.region}")}"
  tenant_id = "${lookup(var.rules[count.index], "tenant_id", "${var.tenant_id}")}"
}
