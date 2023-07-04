terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://proxmox.lan:8006/api2/json"
  pm_api_token_id = "root@pam!terraform"
  pm_api_token_secret = "f73ffbf1-2304-4bfa-9090-0a4227853daf"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "k3s-" {
  count = 3
  target_node = "proxmox"
  name = "k3s-${count.index}"
  clone = "k3s-template"
  full_clone = false
  memory = "512"
  cpu = "host"
  sockets = "1"
  cores = "1"
  
  disk {
    slot = 0
    size = "4G"
    storage = "local-lvm"
	  type = "sata"
  }
  
  network {
    model = "virtio"
    bridge = "vmbr0"
  }
  
  connection {
    type     = "ssh"
    user     = "root"
    password = "Admin!!1"
    host     = "k3s-"
  }
  
  provisioner "remote-exec" {
    inline = [
      "echo k3s-${count.index} >> /etc/hostname",
      "apk add -U python3",
    ]
  }

  depends_on = [proxmox_vm_qemu.k3s-${count.index - 1}]
}

resource "null_resource" "dependency_chain" {
  count = length(proxmox_vm_qemu.k3s-)
  triggers = {
    instance_ids = join(",", proxmox_vm_qemu.k3s-[*].id)
  }
}
