resource "aws_key_pair" "bastion_ssh" {
  key_name   = var.key_pair_name
  public_key = file(var.ssh_key_path)

  tags = merge(
    var.common_tags,
    {
      Name = "bastion_ssh"
    }
  )
}
