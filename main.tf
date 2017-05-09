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
        source_address_prefix = "${var.remote-ip}"
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
# http lb

resource "azurerm_lb_rule" "lb_rule_http" {
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "http"
    protocol = "Tcp"
    frontend_port = 80
    backend_port = 80
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_pool.id}"
    probe_id = "${azurerm_lb_probe.lb-probe.id}"
    frontend_ip_configuration_name = "PublicIPAddress"
}

# https lb

resource "azurerm_lb_rule" "lb_rule_https" {
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "https"
    protocol = "Tcp"
    frontend_port = 443
    backend_port = 443
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_pool.id}"
    probe_id = "${azurerm_lb_probe.lb-probe.id}"
    frontend_ip_configuration_name = "PublicIPAddress"
}

# https nat

# probes

resource "azurerm_lb_probe" "lb-probe" {
    resource_group_name = "${azurerm_resource_group.rs_group.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    protocol = "Tcp"
    name = "dummycheck22"
    port = 22
    interval_in_seconds = 60
}

# - - -
# Storage container
resource "azurerm_storage_account" "account" {
  name                = "${var.env_name}"
  resource_group_name = "${azurerm_resource_group.rs_group.name}"
  location            = "germanycentral"
  account_type        = "Standard_LRS"

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
        admin_password = "${random_id.pw.hex}"
        custom_data = "${ template_file.bootstrap.rendered }"
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
            subnet_id = "${var.snet-id}"
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

# - - - 
# Availability Set

resource "azurerm_availability_set" "av_set" {
    name = "${var.env_name}set"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rs_group.name}"

    tags {
        environment = "${var.env_name}"
    }
    
}