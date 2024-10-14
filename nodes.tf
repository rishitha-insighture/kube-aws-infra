resource "aws_subnet" "knode_subnet" {
  vpc_id            = aws_vpc.kube_test_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1a"

  tags = merge(
    var.common_tags,
    {
      Name = "knode_subnet"
    }
  )
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet1.id

  tags = merge(
    var.common_tags,
    {
      Name = "nat_gw"
    }
  )
}


resource "aws_route_table" "private_rtable" {
  vpc_id = aws_vpc.kube_test_vpc.id

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
  subnet_id      = aws_subnet.knode_subnet.id
  route_table_id = aws_route_table.private_rtable.id
}



resource "aws_security_group" "internal_node_sg" {
  name = "internal_node_sg"
  vpc_id = aws_vpc.kube_test_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
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
  subnet_id      = aws_subnet.knode_subnet.id
  security_groups = [aws_security_group.internal_node_sg.id]

  tags = merge(
    var.common_tags,
    {
      Name = "knode${count.index + 1}_nic"
    }
  )
}

resource "aws_instance" "knode" {
  count          = var.instance_count
  ami            = "ami-008d74584c313ca56"
  instance_type  = "t3.small"
  key_name       = aws_key_pair.bastion_ssh.key_name

  network_interface {
    network_interface_id = aws_network_interface.knode_nic[count.index].id
    device_index         = 0
  }

  tags = merge(
    var.common_tags,
    {
      Name = "knode${count.index + 1}"
    }
  )
}
