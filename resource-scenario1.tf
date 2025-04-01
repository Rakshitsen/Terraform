#  Create a VPC
# ==============================
# VPC CREATION
# ==============================

resource "aws_vpc" "MyVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "MyVPC"
  }
}

# ==============================
# INTERNET GATEWAY
# ==============================

resource "aws_internet_gateway" "MyVPC-IGW" {
  vpc_id = aws_vpc.MyVPC.id

  tags = {
    Name = "MyVPC-IGW"
  }
}

# ==============================
# PUBLIC SUBNET
# ==============================

resource "aws_subnet" "MyVPC-Public-Subnet" {
  vpc_id                  = aws_vpc.MyVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "MyVPC-Public-Subnet"
  }
}

# ==============================
# PRIVATE SUBNET
# ==============================

resource "aws_subnet" "MyVPC-Private-Subnet" {
  vpc_id            = aws_vpc.MyVPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "MyVPC-Private-Subnet"
  }
}

# ==============================
# PUBLIC ROUTE TABLE & ASSOCIATION
# ==============================

resource "aws_route_table" "MyVPC-Public-RT" {
  vpc_id = aws_vpc.MyVPC.id

  tags = {
    Name = "MyVPC-Public-RT"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.MyVPC-Public-Subnet.id
  route_table_id = aws_route_table.MyVPC-Public-RT.id
}

# Route for Public Subnet to reach the Internet via IGW
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.MyVPC-Public-RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.MyVPC-IGW.id
}

# ==============================
# PRIVATE ROUTE TABLE & ASSOCIATION
# ==============================

resource "aws_route_table" "MyVPC-Private-RT" {
  vpc_id = aws_vpc.MyVPC.id

  tags = {
    Name = "MyVPC-Private-RT"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.MyVPC-Private-Subnet.id
  route_table_id = aws_route_table.MyVPC-Private-RT.id
}

# ==============================
# NAT GATEWAY (For Private Subnet Internet Access)
# ==============================

# Allocate an Elastic IP for NAT Gateway
resource "aws_eip" "NAT-EIP" {
  domain = "vpc"

  tags = {
    Name = "NAT-EIP"
  }
}

# Create the NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "MyVPC-NAT" {
  allocation_id = aws_eip.NAT-EIP.id
  subnet_id     = aws_subnet.MyVPC-Public-Subnet.id

  tags = {
    Name = "MyVPC-NAT"
  }
}

# Route for Private Subnet to reach the Internet via NAT Gateway
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.MyVPC-Private-RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.MyVPC-NAT.id
  depends_on             = [aws_nat_gateway.MyVPC-NAT] 
}

# ==============================
# SECURITY GROUP
# ==============================

resource "aws_security_group" "My-Security-Group" {
  description = "Allow HTTP, HTTPS, and SSH access"
  vpc_id      = aws_vpc.MyVPC.id

  # Allow HTTP (Port 80)
  ingress {
    from_port   = 80
    to_port     = 80 
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS (Port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "My-Security-Group"
  }
}

# ==============================
# NETWORK INTERFACE
# ==============================

resource "aws_network_interface" "My-NIC" {
  subnet_id       = aws_subnet.MyVPC-Public-Subnet.id
  security_groups = [aws_security_group.My-Security-Group.id]

  tags = {
    Name = "My-NIC"
  }
}

# Allocate an Elastic IP to the EC2 Network Interface
resource "aws_eip" "EC2-EIP" {
  domain            = "vpc"
  network_interface = aws_network_interface.My-NIC.id

  tags = {
    Name = "EC2-EIP"
  }
}

# ==============================
# EC2 INSTANCE
# ==============================

resource "aws_instance" "myT-Ec2" {
  ami               = "ami-084568db4383264d4"
  instance_type     = "t2.micro"
  key_name          = "us-east-1"
  network_interface_ids = [aws_network_interface.My-NIC.id]

  user_data = <<-EOF
  #!/bin/bash
  sudo apt update 
  sudo apt upgrade -y 
  sudo apt install -y apache2
  sudo systemctl start apache2
  sudo systemctl enable apache2 
  EOF

  tags = {
    Name = "myT-Ec2"
  }
}

