# This block automatically finds the latest Ubuntu 24.04 ID for Mumbai
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "this" {
  # We use the ID found by the data block above
  ami                    = data.aws_ami.ubuntu.id 
  instance_type          = "t3.micro"
  key_name               = "test2"
  subnet_id              = data.aws_subnets.all.ids[0]
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  
  associate_public_ip_address = true

  tags = {
    Name    = "Ubuntu-Admin-Practice"
    Purpose = "terraform-practice"
  }
}

# Create the Internet gateway
resource "aws_internet_gateway" "gw" {
vpc_id = data.aws_vpc.default.id

tags = {
    Name = "Main-IGW"
  }
}

# Tell the route table to send all traffic to the Internet gateway 
resource "aws_route" "internet_access" {
route_table_id = data.aws_vpc.default.main_route_table_id
destination_cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.gw.id
}
# 1 Use the data block we discussed earlier to get your VPC ID automatically
data "aws_vpc" "default" {
  default = true
}

# 2 Create subnet in the default VPC
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls_1"
  description = "Allow TLS inbound traffic and all outbound traffic"
  
  # ADD THIS LINE HERE
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # This means "all protocols"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

output "instance_public_ip" {
  description = "The public IP address of the Ubuntu instance"
  value       = aws_instance.this.public_ip
}