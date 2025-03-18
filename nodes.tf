resource "aws_route_table" "private_rtable" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "private_rtable"
    }
  )
}

resource "aws_route_table_association" "knode_rtable_assoc" {
  subnet_id      = aws_subnet.priv_subnet.id
  route_table_id = aws_route_table.private_rtable.id
}



resource "aws_security_group" "internal_node_sg" {
  name = "internal_node_sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr_range}"]
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
      Name = "internal_node_sg"
    }
  )
}

resource "aws_network_interface" "knode_nic" {
  count          = var.instance_count
  subnet_id      = aws_subnet.priv_subnet.id
  security_groups = [aws_security_group.internal_node_sg.id]
  # associate_public_ip_address = true

  tags = merge(
    var.common_tags,
    {
      Name = "knode${count.index + 1}_nic"
    }
  )
}

resource "aws_instance" "knode" {
  count          = var.instance_count
  ami            = "${var.node_ami_id}"
  instance_type  = "t3.medium"
  key_name       = aws_key_pair.bastion_ssh.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true
    encrypted = true
  }

  network_interface {
    network_interface_id = aws_network_interface.knode_nic[count.index].id
    device_index         = 0
  }

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname knode${count.index + 1}
    echo "127.0.1.1 knode${count.index + 1}" >> /etc/hosts
  EOF

  tags = merge(
    var.common_tags,
    {
      Name = "knode${count.index + 1}"
    }
  )
}

resource "aws_network_interface" "nexus_nic" {
  subnet_id      = aws_subnet.pub_subnet.id
  security_groups = [aws_security_group.internal_node_sg.id]

  tags = merge(
    var.common_tags,
    {
      Name = "nexus_nic"
    }
  )
}

resource "aws_eip" "nexus_eip" {
  domain = "vpc"
  network_interface = aws_network_interface.nexus_nic.id

  tags = merge(
    var.common_tags,
    {
      Name = "nexus_eip"
    }
  )

  depends_on        = [aws_instance.nexus]
}

resource "aws_instance" "nexus" {
  ami            = "${var.node_ami_id}"
  instance_type  = "t3.medium"
  key_name       = aws_key_pair.bastion_ssh.key_name

  network_interface {
    network_interface_id = aws_network_interface.nexus_nic.id
    device_index         = 0
  }

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname nexus
    echo "127.0.1.1 nexus" >> /etc/hosts
  EOF

  tags = merge(
    var.common_tags,
    {
      Name = "nexus"
    }
  )
}
