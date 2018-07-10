provider "external" {
  version = "~> 1.0"
}

# https://github.com/coreos/bugs/issues/1121#issuecomment-390819051

data "external" "verified-image" {
  program = [ "${path.module}/scripts/verify-checksum.sh" ]

  query = {
    base_url = "https://${var.channel}.release.core-os.net/amd64-usr/${var.version}"
    image = "${var.image}"
    signature = "${var.signature}"
    checksums = "${var.checksums}"
    # https://coreos.com/security/image-signing-key/
    public_key = "https://coreos.com/security/image-signing-key/CoreOS_Image_Signing_Key.asc"
    key_id = "0x50E0885593D2DCB4"
  }
}

resource "openstack_images_image_v2" "image" {
  name = "CoreOS ${title(var.channel)} ${var.version}"
  local_file_path = "${data.external.verified-image.result.path}"
  container_format = "bare"
  disk_format = "qcow2"
  min_disk_gb = "${var.min_disk_gb}"
  min_ram_mb = "256"
  verify_checksum = true

  properties {
    sha256checksum = "${data.external.verified-image.result.checksum}"
  }
}
