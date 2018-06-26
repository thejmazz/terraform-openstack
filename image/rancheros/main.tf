# Right now, rancher is only publishing sha256 sums on rancheros.iso,
# Not the -openstack, -digitalocean, etc variants. See:
# - https://releases.rancher.com/os/v1.4.0/iso-checksums.txt
# - https://github.com/rancher/os/releases/download/v1.4.0/checksums.txt

resource "openstack_images_image_v2" "image" {
  name = "RancherOS ${var.version}"
  image_source_url = "https://releases.rancher.com/os/v${var.version}/${var.image}"
  container_format = "bare"
  disk_format = "qcow2"
  min_disk_gb = "8"
  min_ram_mb = "256"
  verify_checksum = true
}
