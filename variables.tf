# List of variables you need to specify for this module to work

# - resource group name
# - location
# - user_data


variable "env_name" {
    type = "string"
    description = "Give your new environment a unique name inside your azure environment. Suggestion: repobranchbuild"
}

variable "location" {
    type = "string"
    description = "Specify your locatio for your new stack"
}

variable "user_data" {
    type = "string"
    description = "Pass on a string for your VM Scale Set to be run at boot time"
}

variable "subnet" {
    type = "string"
    description = "Subnet to allow http/https access from. Suggested: Local VNet at Azure"
    default = "127.16.0.0/12"
}

variable "subnet_id" {
    type = "string"
    description = "ID of the subnet-id to use. Example: /subscriptions/<<subscription-id>>/resourceGroups/<<resource group name>>/providers/Microsoft.Network/virtualNetworks/production/subnets/<<subnet name>>"
}

variable "remote_ip" {
    type = "string"
    description = "Specify the IP or Subnet you want to be able to ssh into the box from"
}

variable "vmsize" {
    type = "string"
    description = "The Size for your VMs"
    default = "Standard_DS1_v2"
}

variable "vmcount" {
    type = "string"
    description = "The amount of VMs for your scale set"
    default = "2"
}

variable "ssh_key" {
    type = "string"
    description = "SSH key to use for the machines"
}

variable "ssh_user" {
    type = "string"
    description = "SSH user to use for the machines"
}

variable "ssh_pw" {
    type = "string"
    description = "SSH user password to use for the machines. Will be disabled anyhow and is purely cosmetic"
}

variable "probe_port" {
    description = "The port for your load balancer health probe"
    default = "22"
}

variable "use_port_probe" {
    description = "Set this to true if you want to have the load balancer us a port Probe"
    default = true
}

variable "probe_url" {
    type = "string"
    description = "Specify a URL for the health probe to use"
    default = "/"
}

variable "use_url_probe" {
    description = "Set this to true if you want to have the load balancer us a http Probe"
    default = false
}

