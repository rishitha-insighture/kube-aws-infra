resource "aws_vpc" "kube_test_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = merge(
    var.common_tags,
    {
      Name = "kube_test_vpc"
    }
  )
}

resource "aws_internet_gateway" "vault_test_igw" {
  vpc_id = aws_vpc.kube_test_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "vault_test_igw"
    }
  )
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.kube_test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = merge(
    var.common_tags,
    {
      Name = "subnet1"
    }
  )
}

resource "aws_route_table" "rtable_1" {
  vpc_id = aws_vpc.kube_test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vault_test_igw.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "rtable_1"
    }
  )
}

resource "aws_route_table_association" "rtable_1_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtable_1.id
}

resource "aws_security_group" "vault_test_sg" {
  name = "vault_test_sg"
  vpc_id = aws_vpc.kube_test_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "vault_test_sg"
    }
  )
}

resource "aws_network_interface" "ec2_gw_nic" {
  subnet_id       = aws_subnet.subnet1.id
  security_groups = [aws_security_group.vault_test_sg.id]

  tags = merge(
    var.common_tags,
    {
      Name = "ec2_gw_nic"
    }
  )
}

resource "aws_eip" "bastion_eip" {
  domain = "vpc"
  network_interface = aws_network_interface.ec2_gw_nic.id

  tags = merge(
    var.common_tags,
    {
      Name = "bastion_eip"
    }
  )

  depends_on        = [aws_instance.bastion]
}

resource "aws_instance" "bastion" {
  ami           = "ami-008d74584c313ca56"
  instance_type = "t2.small"
  key_name      = aws_key_pair.bastion_ssh.key_name

  network_interface {
    network_interface_id = aws_network_interface.ec2_gw_nic.id
    device_index         = 0
  }

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname bastion
    echo "127.0.1.1 bastion" >> /etc/hosts
  EOF

  tags = merge(
    var.common_tags,
    {
      Name = "bastion"
    }
  )
}
