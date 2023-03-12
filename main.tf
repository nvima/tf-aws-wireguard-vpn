terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.55"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    wireguard = {
      source  = "OJFord/wireguard"
      version = "0.2.2"
    }
  }
}

provider "aws" {
  region = local.region
}

locals {
  region = "eu-central-1"
  wg_server_private_key = wireguard_asymmetric_key.server.private_key
  wg_server_public_key  = wireguard_asymmetric_key.server.public_key
  wg_peers = [{
    name        = "peer"
    public_key  = wireguard_asymmetric_key.client.public_key
    allowed_ips = "172.16.16.2,aaaa:bbbb:cccc:dddd:ffff::2/128"
  }]
  wg_server_port  = 51820
  vpn_server_cidr = "172.16.16.0/20,fd42:42:42::1/64"
}

