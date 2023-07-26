terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "4.111.0"
    }
  }
}

resource "oci_core_vcn" "vcn" {
  cidr_blocks    = var.vcn_cidrs
  compartment_id = var.compartment_id
  display_name   = "${var.name}-vcn"
  dns_label      = "${var.name}vcn"
  is_ipv6enabled = true

  lifecycle {
    ignore_changes = [dns_label]
  }
}

resource "oci_core_default_security_list" "lockdown" {
  // If variable is true, removes all rules from default security list
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
  lifecycle {
    ignore_changes = [egress_security_rules, ingress_security_rules, defined_tags]
  }
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-igw"
  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_core_nat_gateway" "nat_gw" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-nat-gw"
  public_ip_id = null
  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-route"
  vcn_id = oci_core_vcn.vcn.id
  route_rules {
    # * With this route table, Internet Gateway is always declared as the default gateway
    destination       = "::/0"
    network_entity_id = oci_core_internet_gateway.igw.id
    description       = "Terraformed - Auto-generated at Internet Gateway creation: Internet Gateway as default gateway"
  }
  route_rules {
    destination = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.nat_gw.id
    description = "Terraformed - Auto-generated at Internet Gateway creation: Internet Gateway as default gateway"
  }
}

resource "oci_core_security_list" "egress" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-egress"
  vcn_id = oci_core_vcn.vcn.id
  egress_security_rules {
    description = "allow all IPv4 Egress"
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    description = "allow all IPv6 Egress"
    destination = "::/0"
    protocol    = "all"
  }
}

resource "oci_core_security_list" "bastion" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-bastion"
  vcn_id = oci_core_vcn.vcn.id
  egress_security_rules {
    description = "allow all IPv4 Egress"
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  egress_security_rules {
    description = "allow all IPv6 Egress"
    destination = "::/0"
    protocol    = "all"
  }
  dynamic "ingress_security_rules" {
    for_each = var.enable_ssh ? { ssh = true } : {}
    content {
      protocol = 6
      source   = "0.0.0.0/0"
      tcp_options {
        min = 22
        max = 22
      }
    }
  }
  dynamic "ingress_security_rules" {
    for_each = var.enable_ssh ? { ssh = true } : {}
    content {
      protocol = 6
      source   = "::/0"
      tcp_options {
        min = 22
        max = 22
      }
    }
  }
}

resource "oci_core_security_list" "tailscale" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-tailscale"
  vcn_id = oci_core_vcn.vcn.id
  ingress_security_rules {
    description = "allow Tailscale easy-NAT"
    source = "0.0.0.0/0"
    protocol = "17"
    // UDP
    udp_options {
      min = 41641
      max = 41641
    }
  }
  ingress_security_rules {
    description = "allow Tailscale easy-NAT IPv6"
    source = "::/0"
    protocol = "17"
    // UDP
    udp_options {
      min = 41641
      max = 41641
    }
  }
}

resource "oci_core_security_list" "icmp" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-icmp"
  vcn_id = oci_core_vcn.vcn.id
  egress_security_rules {
    description = "allow all egress"
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  egress_security_rules {
    description = "allow all egress"
    destination = "::/0"
    protocol    = "all"
  }
  ingress_security_rules {
    description = "allow ICMP type 3, code 4 from everywhere"
    source      = "0.0.0.0/0"
    protocol    = "1" // ICMP
    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    description = "allow ICMP type 3 from 10.0.0.0/16"
    source      = "10.0.0.0/16"
    protocol    = "1" // ICMP
    icmp_options {
      type = 3
    }
  }
  ingress_security_rules {
    description = "allow ICMPv6 type 3, code 4 from everywhere"
    source      = "::/0"
    protocol    = "58" // ICMP
    //    icmp_options {
    //      type = 3
    //      code = 4
    //    }
  }
  ingress_security_rules {
    description = "allow ICMPv6 type 3 from 10.0.0.0/16"
    source      = "2603:c020:800f:2c00::/56"
    protocol    = "58" // ICMP
    //    icmp_options {
    //      type = 3
    //    }
  }
}

resource "oci_core_subnet" "private" {
  cidr_block     = cidrsubnet(oci_core_vcn.vcn.cidr_blocks[0], 8, 0)
  ipv6cidr_block  = cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 0)
  compartment_id = var.compartment_id
  display_name   = "${var.name}-private-0"
  dns_label      = "private0"
  route_table_id = oci_core_route_table.public.id
  vcn_id         = oci_core_vcn.vcn.id
  security_list_ids = [
    oci_core_security_list.tailscale.id,
    oci_core_security_list.icmp.id,
    oci_core_security_list.bastion.id
  ]
}

resource "oci_core_subnet" "public" {
  cidr_block     = cidrsubnet(oci_core_vcn.vcn.cidr_blocks[0], 8, 1)
  ipv6cidr_block  = cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 1)
  compartment_id = var.compartment_id
  display_name   = "${var.name}-public-0"
  dns_label      = "public0"
  route_table_id = oci_core_route_table.public.id
  vcn_id         = oci_core_vcn.vcn.id
  security_list_ids = [
    oci_core_security_list.bastion.id,
    oci_core_security_list.icmp.id,
    oci_core_security_list.tailscale.id
  ]
}
