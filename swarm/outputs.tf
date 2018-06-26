output "swarm-manager-01-floating_ip" {
  value = "${openstack_networking_floatingip_v2.swarm-manager-01.address}"
}

output "swarm_manager_token" {
  value = "${data.external.swarm_tokens.result.manager}"
}

output "swarm_worker_token" {
  value = "${data.external.swarm_tokens.result.worker}"
}

output "swarm_manager_ips" {
  value = [
    "${openstack_compute_instance_v2.swarm-manager-01.network.0.fixed_ip_v4}",
    "${openstack_compute_instance_v2.swarm-managers.*.network.0.fixed_ip_v4}"
  ]
}

output "swarm_worker_ips" {
  value = [
    "${openstack_compute_instance_v2.swarm-workers.*.network.0.fixed_ip_v4}"
  ]
}
