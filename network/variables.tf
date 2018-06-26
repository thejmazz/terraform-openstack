variable "external_network_id" {}

variable "name" {}
variable "admin_state_up" {
  default = "true"
}

variable "dns_nameservers" {
  type = "list"
}

variable "subnets" {
  type = "list"
  default = []
}
