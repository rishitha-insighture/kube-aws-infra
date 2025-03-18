resource "aws_vpc" "main_vpc" {
  cidr_block = "${var.vpc_cidr_range}"
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name = "main_vpc"
    }
  )
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "main_igw"
    }
  )
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "nat_gw_eip"
    }
  )
}

resource "aws_subnet" "pub_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "${var.vpc_public_subnet}"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "pub_subnet"
    }
  )
}

# Private Subnet
resource "aws_subnet" "priv_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "${var.vpc_private_subnet}"
  availability_zone = "${var.aws_region}a"

  tags = merge(
    var.common_tags,
    {
      Name = "priv_subnet"
    }
  )
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.pub_subnet.id

  tags = merge(
    var.common_tags,
    {
      Name = "nat_gw"
    }
  )

  depends_on = [aws_subnet.pub_subnet]
}

resource "aws_route_table" "rtable_1" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "rtable_1"
    }
  )

  depends_on = [aws_subnet.pub_subnet]
}

resource "aws_route_table_association" "rtable_1_association" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.rtable_1.id

  depends_on = [aws_route_table.rtable_1]
}

resource "aws_security_group" "bastion_pub_sg" {
  name = "bastion_pub_sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      description      = "Allow all inbound traffic"
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "bastion_pub_sg"
    }
  )
}

resource "aws_security_group" "bastion_private_sg" {
  name        = "bastion_private_sg"
  description = "Security group for bastion private interface"
  vpc_id      = aws_vpc.main_vpc.id


  # Allow ALL inbound traffic from anywhere (including private networks)
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      description      = "Allow all inbound traffic"
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  # Allow ALL outbound traffic to anywhere (including private networks)
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      description      = "Allow all outbound traffic"
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  # name_prefix = null
  tags = merge(
    var.common_tags,
    {
      Name = "bastion_private_sg"
    }
  )
}

resource "aws_network_interface" "public_nic" {
  subnet_id       = aws_subnet.pub_subnet.id
  security_groups = [aws_security_group.bastion_pub_sg.id]

  tags = merge(
    var.common_tags,
    {
      Name = "bastion_public_nic"
    }
  )

  depends_on = [ aws_security_group.bastion_pub_sg ]
}

resource "aws_network_interface" "private_nic" {
  subnet_id       = aws_subnet.priv_subnet.id
  security_groups = [aws_security_group.bastion_private_sg.id]
  source_dest_check  = false

  tags = merge(
    var.common_tags,
    {
      Name = "bastion_private_nic"
    }
  )

  depends_on = [ aws_security_group.bastion_private_sg ]
}

resource "aws_eip" "bastion_eip" {
  domain = "vpc"
  network_interface = aws_network_interface.public_nic.id

  tags = merge(
    var.common_tags,
    {
      Name = "bastion_eip"
    }
  )

  depends_on        = [aws_instance.bastion]
}

resource "aws_instance" "bastion" {
  ami           = "${var.bastion_ami_id}"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.bastion_ssh.key_name

  network_interface {
    network_interface_id = aws_network_interface.public_nic.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.private_nic.id
    device_index         = 1
  }

  tags = merge(
    var.common_tags,
    {
      Name = "bastion"
    }
  )
}
