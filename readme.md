# Terraform Module for Azure LB deployments

Use this module to quickly deploy a VMSS with Loadbalancer and ports 22, 80 and 443 forwarded to your machines.

## Usage

An example says more than words:

```
provider "azurerm" {
    subscription_id = "${var.subscription_id}"
    client_id = "${var.client_id}"
    client_secret = "${var.client_secret}"
    tenant_id = "${var.tenant_id}"
    environment = "german" (optional)
}

module "deployment" {
    source = "github.com/benkoller/tf-azure-stack.git"

    env_name = "nameForYourEnvironment"
    location = "Germany Central" (yes, sovereign clouds work)
    user_data = "docker run helloworld"
    subnet = "your Azure Subnets CIDR"
    remote_ip = "your office ip as CIDR/32"
    vmsize = "Standard_DS1_v2"
    vmcount = "2"
    ssh_key = "ssh-rsa AAAA(...)"
    ssh_user = "user"
    ssh_pw = "some_pw"
    subnet_id = "/subscriptions/<id>/resourceGroups/prod/providers/Microsoft.Network/virtualNetworks/production/subnets/<subnet_name>"
    use_port_probe = false
    # probe_port = "22"
    use_url_probe = true
    probe_url = "/healthcheck.php"
}