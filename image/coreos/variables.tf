variable "channel" {
  default = "stable"
}
# stable, beta, alpha

# "mini image w/o resized root parition" - https://github.com/coreos/bugs/issues/1121#issuecomment-352076733

# e.g. 1745.7.0
variable "version" {}

variable "min_disk_gb" {
  default = "10"
}
# 8.5 for regular, 4.5 for mini

variable "image" {
  default = "coreos_production_openstack_image.img.bz2"
}
# mini: coreos_production_openstack_mini_image.img.bz2

variable "signature" {
  default = "coreos_production_openstack.DIGESTS.sig"
}
# mini: coreos_production_openstack_mini.DIGESTS.sig

variable "checksums" {
  default = "coreos_production_openstack.DIGESTS"
}
# mini: coreos_production_openstack_mini.DIGESTS
