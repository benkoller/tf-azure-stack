# Module to create a VMSS with a LB in their own Resource Group 

# - - - - - - - - - - - - - - - - - - - - 
# Ignore the next part
# I need to protect people from themselves. Lets not use any special chars!
variable "safe_env" {
    type = "string"
    description = "describe your variable"
    default = "${lower(${replace(${var.env_name}, "[^[:alnum:]]", "")})}"
}

# Stop ignoring.
# - - - - - - - - - - - - - - - - - - - - 


resource "azurerm_resource_group" "rs_group" {
  name     = "${var.env_name}"
  location = "${var.location}"

  tags {
        environment = "${var.env_name}"
    }
}

resource "azurerm_network_security_group" "sg" {
    name = "${var.env_name}SG"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"

    security_rule {
        name = "localhttp"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "${var.subnet}"
        destination_address_prefix = "*"
        access = "Allow"
        priority = 1001
        direction = "Inbound"
    }

    security_rule {
        name = "localhttps"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "443"
        source_address_prefix = "${var.subnet}"
        destination_address_prefix = "*"
        access = "Allow"
        priority = 1002
        direction = "Inbound"
    }

    security_rule {
        name = "remoteSSH"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "${var.remote_ip}"
        destination_address_prefix = "*"
        access = "Allow"
        priority = 2000
        direction = "Inbound"
    }

    tags {
        environment = "${var.env_name}"
    }
}


# - - - 
# Public loadbalancer IP

resource "azurerm_public_ip" "lb_pip" {
    name = "${var.env_name}PIP"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    public_ip_address_allocation = "static"
    domain_name_label = "p${var.env_name}"

    tags {
        environment = "${var.env_name}"
    }
}

# - - - 
# Load balancer block
# Load balancer

resource "azurerm_lb" "lb" {
  name                = "${var.env_name}LB"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rs_group.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.lb_pip.id}"
  }
}

# LB address pool

resource "azurerm_lb_backend_address_pool" "lb_pool" {
  resource_group_name = "${azurerm_resource_group.rs_group.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "lbPool"
}

# - - -
# Load balancer behaviour
# PORT-PROBE
# http lb

resource "azurerm_lb_rule" "lb_rule_http_port" {
    count = "${var.use_port_probe}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "http"
    protocol = "Tcp"
    frontend_port = 80
    backend_port = 80
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_pool.id}"
    probe_id = "${azurerm_lb_probe.lb-probe-port.id}"
    frontend_ip_configuration_name = "PublicIPAddress"
    # load_distribution = "SourceIPProtocol"
}

# https lb

resource "azurerm_lb_rule" "lb_rule_https_port" {
    count = "${var.use_port_probe}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "https"
    protocol = "Tcp"
    frontend_port = 443
    backend_port = 443
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_pool.id}"
    probe_id = "${azurerm_lb_probe.lb-probe-port.id}"
    frontend_ip_configuration_name = "PublicIPAddress"
    # load_distribution = "SourceIPProtocol"
}

# ssl lb

# resource "azurerm_lb_rule" "lb_rule_ssh_port" {
#     count = "${var.use_port_probe}"
#     resource_group_name = "${azurerm_resource_group.rs_group.name}"
#     loadbalancer_id = "${azurerm_lb.lb.id}"
#     name = "ssh"
#     protocol = "Tcp"
#     frontend_port = 22
#     backend_port = 22
#     backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_pool.id}"
#     probe_id = "${azurerm_lb_probe.lb-probe-port.id}"
#     frontend_ip_configuration_name = "PublicIPAddress"
# }

# Load balancer behaviour
# URL-PROBE!
# http lb

resource "azurerm_lb_rule" "lb_rule_http_url" {
    count = "${var.use_url_probe}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "http"
    protocol = "Tcp"
    frontend_port = 80
    backend_port = 80
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_pool.id}"
    probe_id = "${azurerm_lb_probe.lb-probe-http.id}"
    frontend_ip_configuration_name = "PublicIPAddress"
    # load_distribution = "SourceIPProtocol"
}

# https lb

resource "azurerm_lb_rule" "lb_rule_https_url" {
    count = "${var.use_url_probe}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "https"
    protocol = "Tcp"
    frontend_port = 443
    backend_port = 443
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_pool.id}"
    probe_id = "${azurerm_lb_probe.lb-probe-http.id}"
    frontend_ip_configuration_name = "PublicIPAddress"
    # load_distribution = "SourceIPProtocol"
}

# ssl lb

# resource "azurerm_lb_rule" "lb_rule_ssh_url" {
#     count = "${var.use_url_probe}"
#     resource_group_name = "${azurerm_resource_group.rs_group.name}"
#     loadbalancer_id = "${azurerm_lb.lb.id}"
#     name = "ssh"
#     protocol = "Tcp"
#     frontend_port = 22
#     backend_port = 22
#     backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_pool.id}"
#     probe_id = "${azurerm_lb_probe.lb-probe-http.id}"
#     frontend_ip_configuration_name = "PublicIPAddress"
# }


# - - -
# probes

resource "azurerm_lb_probe" "lb-probe-port" {
    count = "${var.use_port_probe}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    protocol = "Tcp"
    name = "probe${var.probe_port}"
    port = "${var.probe_port}"
    interval_in_seconds = 60
}

resource "azurerm_lb_probe" "lb-probe-http" {
    count = "${var.use_url_probe}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    protocol = "Http"
    name = "probeHttp"
    port = "${var.probe_port}"
    request_path = "${var.probe_url}"
    interval_in_seconds = 60
}

# - - -
# Storage container
resource "azurerm_storage_account" "account" {
  name                = "${var.env_name}"
  resource_group_name = "${azurerm_resource_group.rs_group.name}"
  location            = "germanycentral"
  account_tier        = "Standard"
  account_replication_type = "GRS"

  tags {
    environment = "${var.env_name}"
  }
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "${var.env_name}vhds"
  resource_group_name   = "${azurerm_resource_group.rs_group.name}"
  storage_account_name  = "${azurerm_storage_account.account.name}"
  # storage_account_name = "terraform"
  container_access_type = "private"
}

# - - - 
# Virtual Machine Scale Set

resource "azurerm_virtual_machine_scale_set" "vmss" {
    name = "${var.env_name}VM"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    # network_interface_ids = ["${azurerm_network_interface.deploy-nic.id}"]
    upgrade_policy_mode = "Automatic"
    # vm_size = "Standard_D1_v2"

    sku {
        name = "${var.vmsize}"
        tier = "Standard"
        capacity = "${var.vmcount}"
    }

    os_profile {
        computer_name_prefix = "${var.env_name}"
        admin_username = "${var.ssh_user}"
        admin_password = "${var.ssh_pw}"
        custom_data = "${var.user_data }"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path = "/home/${var.ssh_user}/.ssh/authorized_keys"
            key_data = "${var.ssh_key}"
        }
    }

    network_profile {
        name    = "deployNetworkProfile"
        primary = true

        ip_configuration {
            name = "TestIPConfiguration"
            subnet_id = "${var.subnet_id}"
            load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.lb_pool.id}"]
        }
    }

    storage_profile_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04-LTS"
        version = "latest"
    }

    storage_profile_os_disk {
        name = "deployOS"
        vhd_containers = ["${azurerm_storage_account.account.primary_blob_endpoint}${azurerm_storage_container.storage_container.name}"]
        caching = "ReadWrite"
        create_option = "FromImage"
        os_type = "linux"
    }

    tags {
        environment = "${var.env_name}"
    }

    depends_on = ["azurerm_lb.lb", "azurerm_storage_container.storage_container"]
}

output "public_ip_address" {
    value = "${azurerm_public_ip.lb_pip.ip_address}"
}

output "pip_id" {
    value = "${azurerm_public_ip.lb_pip.id}"
}

output "resource_group_name" {
    value = "${var.env_name}"
}

output "resource_group_id" {
    value = "${azurerm_resource_group.rs_group.id}"
}
