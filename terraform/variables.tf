# AWS Configurations
variable "region" {
  description = "The AWS region in which we'll create this Terraform module"
  type        = string
}

variable "allowed_availability_zone_ids" {
  # Note, this is Zone IDs, not Zone Names
  # https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html
  type        = list(any)
  description = "Which availability zone ID should we spin up Wireguard instances in?"
}

variable "ssh_key_id" {
  description = "Which SSH key ID to allow access to the Wireguard VPN instances"
  type        = string
}

# Compute (Instance+ASG+Spot) Configurations
variable "instance_type" {
  description = "Instance size to use for the Wireguard VPN instance"
  default     = "t3a.nano"
  type        = string
}

variable "asg_min_size" {
  type        = number
  default     = 1
  description = "Minimum number of instances in the Auto Scaling Group"
}

variable "asg_max_size" {
  type        = number
  default     = 2
  description = "Maximum number of instances in the Auto Scaling Group"
}

variable "asg_desired_size" {
  type        = number
  default     = 1
  description = "Desired number of instances in the Auto Scaling Group"
}

variable "spot_max_price" {
  type        = string
  description = "Maximum price for Spot Instances that you're willing to pay in USD"
}

# Network Configurations
# A /25 is recommended, can be a wider range than this
# Here's how to compute this: 
# Number of maximum IPs in _one_ availability zone/subnet * number of allowed subnets * 2 (private + public) 
# should be greater than the number of Hosts listed on http://jodies.de/ipcalc for your range.
# The lowest AWS allows us to go is /28.
variable "vpc_cidr_range" {
  type        = string
  default     = "10.0.0.0/25"
  description = "Range of IP addresses in the AWS Virtual Private Network"
}

variable "ssh_allow_ip_range" {
  type        = list(string)
  description = "Which IP addresses to allow ssh access from"
  default     = ["127.0.0.1/32"]
}

# Wireguard configurations
variable "wg_server_private_key_path" {
  description = "The SSM parameter configuration path containing the private key for the Wireguard server"
  type        = string
}

variable "wg_server_listen_addr" {
  type        = string
  description = "IP Address of the Wireguard server on the VPN"
  default     = "10.0.1.1"
}

variable "wg_server_port" {
  description = "The port that Wireguard server is available on"
  type        = number
  default     = 51820
}

# 
# wg_client_pub_keys = [ 
#   { name = "dummy1", ip_addr = "10.0.1.2", pub_key = "foobarbaz=" },
#   { name = "dummy2", ip_addr = "10.0.1.3", pub_key = "foobarbax=" },
#   { name = "dummy3", ip_addr = "10.0.1.4", pub_key = "foobarbac=" }
# ]
# 
variable "wg_client_pub_keys" {
  type = list(object({
    name    = string
    ip_addr = string
    pub_key = string
  }))
  description = "List of maps of Client IPs and Public keys, as described in README"
}

# Custom post provisioning steps, if any
variable "post_provisioning_steps" {
  description = "Optional set of commands to execute once the wireguard server has been provisioned. Is executed in the cloud-init environment via the user-data parameter"
  type        = string
  default     = ""
}

variable "codebuild_source_repo" {
  description = "Code build source repo to use"
  type        = string
  default     = "https://github.com/Yabes/thrift-vpn.git"
}

variable "dns_zone" {
  description = "DNS Zone to update with instance IP"
  type        = string
}
