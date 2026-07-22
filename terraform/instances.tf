# Generate SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# Save private key to local file
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "${path.module}/cpouta_key.pem"
  file_permission = "0600"
}

# Upload public key to OpenStack
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "k8s-cluster-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Instance 1: Master Gateway Instance
resource "openstack_compute_instance_v2" "k8s_master" {
  name            = "k8s-master"
  image_name      = "Ubuntu-22.04"        # Verify image name in cPouta dashboard
  flavor_name     = "standard.medium"     # Adjust flavor size as needed
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [
    openstack_networking_secgroup_v2.secgroup_public.name,
    openstack_networking_secgroup_v2.secgroup_internal.name
  ]

  network {
    uuid        = openstack_networking_network_v2.k8s_net.id
    fixed_ip_v4 = "192.168.1.10"
  }
}

# Instance 2: Worker Instance (Internal Only)
resource "openstack_compute_instance_v2" "k8s_worker" {
  name            = "k8s-worker"
  image_name      = "Ubuntu-22.04"
  flavor_name     = "standard.medium"
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [
    openstack_networking_secgroup_v2.secgroup_internal.name
  ]

  network {
    uuid        = openstack_networking_network_v2.k8s_net.id
    fixed_ip_v4 = "192.168.1.11"
  }
}

# Allocate Floating IP from Public Pool
resource "openstack_networking_floatingip_v2" "fip" {
  pool = "public"
}

# Attach Floating IP to Master Node (using compute association for compatibility)
resource "openstack_compute_floatingip_associate_v2" "fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  instance_id = openstack_compute_instance_v2.k8s_master.id
}

# Output Public and Internal IPs
output "master_public_ip" {
  value = openstack_networking_floatingip_v2.fip.address
}

output "master_private_ip" {
  value = openstack_compute_instance_v2.k8s_master.network[0].fixed_ip_v4
}

output "worker_private_ip" {
  value = openstack_compute_instance_v2.k8s_worker.network[0].fixed_ip_v4
}

output "ssh_private_key_path" {
  value = local_file.private_key.filename
  description = "Path to the generated SSH private key"
}

output "ssh_command" {
  value = "ssh -i ${local_file.private_key.filename} ubuntu@${openstack_networking_floatingip_v2.fip.address}"
  description = "Command to SSH into the master node"
}

# Note: Ansible inventory generation removed
# The main deployment script (deploy-k8s-cluster.ps1) uses direct SSH commands
# Ansible playbooks are archived in ansible-reference-backup/ for reference only