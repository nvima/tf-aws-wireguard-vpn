output "instance_id" {
  value = aws_instance.wireguard.id
}

output "region" {
  value = local.region
}

output "ip_address" {
  value = aws_instance.wireguard.public_ip
}

output "ssh_connection" {
  value = "ssh ec2-user@${aws_instance.wireguard.public_ip}"
}

output "client_config" {
  value = templatefile("resources/wireguard-client-conf.tpl", {
    interface_address        = "172.16.16.2/20"
    interface_dns            = "1.1.1.1"
    interface_mtu            = "1280"
    interface_privatekey     = wireguard_asymmetric_key.client.private_key
    peer_endpoint            = "${aws_instance.wireguard.public_ip}:51820"
    peer_publickey           = wireguard_asymmetric_key.server.public_key
    peer_allowedips          = "0.0.0.0/0, ::/0"
    peer_persistentkeepalive = 15
  })
  sensitive = true
}
