output "rancher-floating_ip" {
  value = "${openstack_networking_floatingip_v2.rancher.address}"
}
