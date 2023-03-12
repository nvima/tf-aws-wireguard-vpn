resource "aws_key_pair" "wireguard" {
    key_name   = "wireguard"
    public_key = file("~/.ssh/id_rsa.pub")
}
