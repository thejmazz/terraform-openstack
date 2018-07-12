variable external_network_id {}
variable external_network_name {}

// === NETWORK ===

variable network_name {
  default = "bootstrap"
}

variable subnet_name {
  default = "bootstrap_subnet"
}

# general format is a.b.c.n with
# cidr: a.b.c.0/24 for 256 IPs
# gateway: a.b.c.1
# start: a.b.c.2
# end: a.b.c.254

variable subnet_cidr {
  default = "192.168.0.0/24"
}

variable subnet_gateway_ip {
  default = "192.168.0.1"
}

variable subnet_allocation_pools_start {
  default = "192.168.0.2"
}

variable subnet_allocation_pools_end {
  default = "192.168.0.254"
}

// We assume two DNS serves will exist at the start of the allocation pool.
// 172.17.254.254 is added to stop Docker from creating any 172.17.0.0/16 interfaces. See:
// - https://github.com/moby/moby/issues/21776#issuecomment-230377605
// - default-address-pools in 18.06: https://github.com/moby/moby/pull/36396
variable subnet_dns_nameservers {
 default = [
    "192.168.0.2",
    "192.168.0.3",
    "172.17.254.254"
  ]
}

// === SECURITY GROUPS ===

variable ssh_cidr_sources {
  type = "list"
  default = []
}

// === KEY PAIR ===

variable public_key {}

// === INSTANCE ===

variable flavor {
  default = "m1.medium"
}
