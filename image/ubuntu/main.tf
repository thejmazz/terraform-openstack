provider "external" {
  version = "~> 1.0"
}

# TODO how to handle case when image was partially downloaded, so check fails?

# TODO given ARCHITECTURE, find out image url:
# - https://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img
# - https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.img
# (take file that has both amd64 and \.img$)

# NOTE downloads image on a plan

# from: https://wiki.ubuntu.com/SecurityTeam/FAQ#GPG_Keys_used_by_Ubuntu
# pub   4096R/7DB87C81 2009-09-15
#       Key fingerprint = D2EB 4462 6FDD C30B 513D  5BB7 1A5D 6C4C 7DB8 7C81
# uid                  UEC Image Automatic Signing Key <cdimage@ubuntu.com>

# TODO need to do a better unique cache_path that handles specific releases
data "external" "verified-image" {
  program = [ "${path.module}/scripts/verify-checksum.sh" ]

  query = {
    base_url = "https://cloud-images.ubuntu.com/releases/${var.version}/${var.release}"
    image = "${var.image}"
    signature = "SHA256SUMS.gpg"
    checksums = "SHA256SUMS"
    keyserver = "hkp://keyserver.ubuntu.com"
    key_id = "0x7DB87C81"
  }
}

resource "openstack_images_image_v2" "image" {
  # TODO include release date
  name = "Ubuntu ${var.version}"
  local_file_path = "${data.external.verified-image.result.path}"
  container_format = "bare"
  disk_format = "qcow2"
  min_disk_gb = "8"
  min_ram_mb = "256"
  verify_checksum = true

  # TODO also grab release date
  properties {
    sha256checksum = "${data.external.verified-image.result.checksum}"
  }
}
