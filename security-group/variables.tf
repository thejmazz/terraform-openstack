variable name {}
variable description {
  default = ""
}
variable region {
  default = ""
}
variable tenant_id {
  default = ""
}
variable delete_default_rules {
  default = "false"
}

variable rule_default_direction {
  default = "ingress"
}

variable rules {
  type = "list"
  default = []
}
