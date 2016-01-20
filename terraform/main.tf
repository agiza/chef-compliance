variable "vcd_org" {}
variable "vcd_userid" {}
variable "vcd_pass" {}
variable "ext_ip" {}
variable "testserver_count" { default = 2 }
variable "chef_client_version" { default = "12.6.0" }
variable "root_password" {}
variable "audit_ip" { default = "10.20.0.152" }

# Configure the VMware vCloud Director Provider
provider "vcd" {
    user            = "${var.vcd_userid}"
    org             = "${var.vcd_org}"
    url				= "https://api.vcd.portal.skyscapecloud.com/api"
    password        = "${var.vcd_pass}"
}

# Create a new network
resource "vcd_network" "mgt_net" {
    name = "Management Network"
    edge_gateway = "Edge Gateway Name"
    gateway = "10.20.0.1"

    static_ip_pool {
        start_address = "10.20.0.152"
        end_address = "10.20.0.254"
    }
}

resource "vcd_network" "test_net" {
    name = "Test Network"
    edge_gateway = "Edge Gateway Name"
    gateway = "10.30.0.1"

    dhcp_pool {
        start_address = "10.30.0.2"
        end_address = "10.30.0.100"
    }
}

resource "vcd_vapp" "compliance" {
    name          = "audit01"
    catalog_name  = "DevOps"
    template_name = "centos71"
    memory        = 2048
    cpus          = 1

    network_name  = "${vcd_network.mgt_net.name}"
    ip = "${var.audit_ip}"

    provisioner "chef"  {
        run_list = ["chef-compliance::default"]
        node_name = "${vcd_vapp.compliance.name}"
        server_url = "https://api.chef.io/organizations/skyscapecloud"
        validation_client_name = "skyscapecloud-validator"
        validation_key = "${file("~/.chef/skyscapecloud-validator.pem")}"
        version = "${var.chef_client_version}"
        connection {
            host = "${var.ext_ip}"
            user = "vagrant"
            password = "${var.root_password}"
        }
    }
}

resource "vcd_vapp" "testservers" {
    name          = "${format("test%02d", count.index + 1)}"
    catalog_name  = "DevOps"
    template_name = "centos71"
    memory        = 512
    cpus          = 1

    count         = "${var.testserver_count}"

    network_name  = "${vcd_network.test_net.name}"
}

resource "vcd_dnat" "compliance-ssh" {
    edge_gateway  = "Edge Gateway Name"
    external_ip   = "${var.ext_ip}"
    port          = 22
    internal_ip   = "${var.audit_ip}"
}

resource "vcd_dnat" "compliance-https" {
    edge_gateway  = "Edge Gateway Name"
    external_ip   = "${var.ext_ip}"
    port          = 443
    internal_ip   = "${var.audit_ip}"
}

resource "vcd_snat" "mgt-outbound" {
    edge_gateway = "Edge Gateway Name"
    external_ip  = "${var.ext_ip}"
    internal_ip  = "10.20.0.0/24"
}

resource "vcd_snat" "test-outbound" {
    edge_gateway = "Edge Gateway Name"
    external_ip  = "${var.ext_ip}"
    internal_ip  = "10.30.0.0/24"
}

resource "vcd_firewall_rules" "demo-fw" {
    edge_gateway   = "Edge Gateway Name"
    default_action = "drop"

    rule {
        description      = "allow-compliance-ssh"
        policy           = "allow"
        protocol         = "tcp"
        destination_port = "22"
        destination_ip   = "${vcd_dnat.compliance-ssh.external_ip}"
        source_port      = "any"
        source_ip        = "any"
    }

    rule {
        description      = "allow-compliance-https"
        policy           = "allow"
        protocol         = "tcp"
        destination_port = "443"
        destination_ip   = "${vcd_dnat.compliance-https.external_ip}"
        source_port      = "any"
        source_ip        = "any"
    }

    rule {
        description      = "allow-chef-outbound"
        policy           = "allow"
        protocol         = "any"
        destination_port = "any"
        destination_ip   = "any"
        source_port      = "any"
        source_ip        = "10.20.0.0/24"
    }

    rule {
        description      = "allow-internal"
        policy           = "allow"
        protocol         = "any"
        destination_port = "any"
        destination_ip   = "10.0.0.0/8"
        source_port      = "any"
        source_ip        = "10.0.0.0/8"
    }
}
