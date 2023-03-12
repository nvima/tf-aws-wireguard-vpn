resource "aws_instance" "wireguard" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3a.nano"
  subnet_id              = resource.aws_default_subnet.default.id
  vpc_security_group_ids = [aws_security_group.wireguard.id]
  user_data              = data.template_file.wireguard_userdata.rendered
  key_name               = aws_key_pair.wireguard.key_name
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
}

data "template_file" "wireguard_userdata_peers" {
  template = file("resources/wireguard-user-data-peers.tpl")
  count    = length(local.wg_peers)
  vars = {
    peer_name        = local.wg_peers[count.index].name
    peer_public_key  = local.wg_peers[count.index].public_key
    peer_allowed_ips = local.wg_peers[count.index].allowed_ips
  }
}

data "template_file" "wireguard_userdata" {
  template = file("resources/wireguard-user-data.tpl")
  vars = {
    client_network_cidr   = local.vpn_server_cidr
    wg_server_private_key = local.wg_server_private_key
    wg_server_public_key  = local.wg_server_public_key
    wg_server_port        = local.wg_server_port
    wg_peers              = join("\n", data.template_file.wireguard_userdata_peers[*].rendered)
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}
