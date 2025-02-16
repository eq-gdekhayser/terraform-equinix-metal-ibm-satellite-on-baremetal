resource "tls_private_key" "ssh_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "metal_ssh_key" "ssh_pub_key" {
  name       = local.stack_name
  public_key = chomp(tls_private_key.ssh_key_pair.public_key_openssh)
}

resource "local_file" "cluster_private_key_pem" {
  content         = chomp(tls_private_key.ssh_key_pair.private_key_pem)
  filename        = pathexpand(format("~/.ssh/%s", local.ssh_key_name))
  file_permission = "0600"
}

data "template_file" "user_data" {
  template = file("templates/user_data.sh")
  vars = {
    operating_system = var.operating_system
  }
}

resource "metal_project" "new_project" {
  count           = var.metal_create_project ? 1 : 0

  name            = var.metal_project_name
  organization_id = var.metal_organization_id
}

resource "metal_device" "control_plane" {
  count = var.ibm_cp_host_count

  depends_on = [
    metal_ssh_key.ssh_pub_key
  ]
  hostname                = format("%s-cp-%02d", local.stack_name, count.index + 1)
  plan                    = var.control_plane_plan
  metro                   = var.metal_device_metro
  operating_system        = var.operating_system
  billing_cycle           = var.billing_cycle
  project_id              = local.metal_project_id
  user_data               = data.template_file.user_data.rendered
  hardware_reservation_id = lookup(var.metal_device_reservations, format("%s-cp-%02d", local.stack_name, count.index + 1), "")
  tags                    = concat(["app:ibm-satellite"], var.ibm_cp_host_labels)
}

resource "metal_device" "data_plane" {
  count = var.ibm_dp_host_count

  depends_on = [
    metal_ssh_key.ssh_pub_key
  ]
  hostname                = format("%s-worker-%02d", local.stack_name, count.index + 1)
  plan                    = var.data_plane_plan
  metro                   = var.metal_device_metro
  operating_system        = var.operating_system
  billing_cycle           = var.billing_cycle
  project_id              = local.metal_project_id
  user_data               = data.template_file.user_data.rendered
  hardware_reservation_id = lookup(var.metal_device_reservations, format("%s-cp-%02d", local.stack_name, count.index + 1), "")
  tags                    = concat(["app:ibm-satellite"], var.ibm_dp_host_labels)
}

resource "null_resource" "write_ssh_private_key" {

  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.control_plane.0.access_public_ipv4
    timeout     = "10m"
  }

  provisioner "file" {
    content     = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    destination = "/root/.ssh/id_rsa"
  }
  provisioner "remote-exec" {
    inline = ["chmod 0400 /root/.ssh/id_rsa"]
  }
}

data "template_file" "pre_reqs_cluster" {
  template = file("${path.module}/templates/pre_reqs_cluster.sh")
  vars = {
    operating_system = var.operating_system
    rhel_username    = var.rhel_submanager_username
    rhel_password    = var.rhel_submanager_password
  }
}

resource "null_resource" "deploy_satellite_cluster_cp" {
  count = var.ibm_cp_host_count

  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.control_plane.*.access_public_ipv4[count.index]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/bootstrap/"
    ]
  }

  provisioner "file" {
    content     = data.template_file.pre_reqs_cluster.rendered
    destination = "/root/bootstrap/pre_reqs.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash /root/bootstrap/pre_reqs.sh"]
  }

  provisioner "file" {
    content     = data.ibm_satellite_attach_host_script.script_cp.host_script
    destination = "/root/bootstrap/attach_satellite_cp_host.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /root/bootstrap/attach_satellite_cp_host.sh"
    ]
  }
}

resource "null_resource" "deploy_satellite_cluster_worker" {
  count = var.ibm_dp_host_count

  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.data_plane.*.access_public_ipv4[count.index]
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/bootstrap/"
    ]
  }

  provisioner "file" {
    content     = data.template_file.pre_reqs_cluster.rendered
    destination = "/root/bootstrap/pre_reqs.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash /root/bootstrap/pre_reqs.sh"]
  }

  provisioner "file" {
    content     = data.ibm_satellite_attach_host_script.script_dp.host_script
    destination = "/root/bootstrap/attach_satellite_worker_host.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /root/bootstrap/attach_satellite_worker_host.sh"
    ]
  }
}