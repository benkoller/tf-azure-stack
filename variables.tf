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