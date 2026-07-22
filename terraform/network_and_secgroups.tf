# 1. Private Network
resource "openstack_networking_network_v2" "k8s_net" {
  name           = "k8s-internal-network"
  admin_state_up = true
}

# 2. Private Subnet
resource "openstack_networking_subnet_v2" "k8s_subnet" {
  name            = "k8s-internal-subnet"
  network_id      = openstack_networking_network_v2.k8s_net.id
  cidr            = "192.168.1.0/24"
  ip_version      = 4
  dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

# 3. Router connected to cPouta External Network
data "openstack_networking_network_v2" "public_net" {
  name = "public"
}

resource "openstack_networking_router_v2" "k8s_router" {
  name                = "k8s-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public_net.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.k8s_router.id
  subnet_id = openstack_networking_subnet_v2.k8s_subnet.id
}

# 4. Security Group: External (Public Master)
resource "openstack_networking_secgroup_v2" "secgroup_public" {
  name        = "k8s-public-secgroup"
  description = "Public ingress rules for Master node"
}

# Rule: SSH (Port 22)
resource "openstack_networking_secgroup_rule_v2" "rule_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_public.id
}

# Rule: HTTP Web Traffic (Port 80)
resource "openstack_networking_secgroup_rule_v2" "rule_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_public.id
}

# Rule: Argo CD Dashboard (Port 8080)
resource "openstack_networking_secgroup_rule_v2" "rule_argocd" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_public.id
}

# Rule: HTTPS (Port 443) for Argo CD / Secure Access
resource "openstack_networking_secgroup_rule_v2" "rule_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_public.id
}

# Rule: Kubernetes API Server (Port 6443) for k3s
resource "openstack_networking_secgroup_rule_v2" "rule_k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_public.id
}

# Rule: NodePort React App (Port 30007)
resource "openstack_networking_secgroup_rule_v2" "rule_nodeport" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30007
  port_range_max    = 30007
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_public.id
}

# Rule: NodePort Argo CD (Port 30008)
resource "openstack_networking_secgroup_rule_v2" "rule_argocd_nodeport" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30008
  port_range_max    = 30008
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_public.id
}

# 5. Security Group: Full Internal Inter-Node Communication
resource "openstack_networking_secgroup_v2" "secgroup_internal" {
  name        = "k8s-internal-secgroup"
  description = "Allows all internal subnet nodes to communicate"
}

resource "openstack_networking_secgroup_rule_v2" "rule_internal_all" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "" # All protocols
  remote_ip_prefix  = "192.168.1.0/24"
  security_group_id = openstack_networking_secgroup_v2.secgroup_internal.id
}

# Note: Egress rules are automatically created by OpenStack and allow all outbound traffic by default