provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_vpc" "faastest" {
  cidr_block            = "10.1.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = {
    Name = "faastest"
  }
}

resource "aws_subnet" "faastest_subnet" {
  cidr_block        = "10.1.1.0/24"
  vpc_id            = aws_vpc.faastest.id
  availability_zone = "${var.region}a"
}

resource "aws_security_group" "faastest" {
  name    = "faastest-sg"
  vpc_id  = aws_vpc.faastest.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "faastest" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = var.key_pair_name
  subnet_id       = aws_subnet.faastest_subnet.id
  security_groups = [aws_security_group.faastest.id]

  tags = {
    Name = "faastest"
  }
}

resource "aws_eip" "faastest_ip" {
  instance = aws_instance.faastest.id
  vpc      = true
}

resource "null_resource" "installation" {
  triggers = {
    instance = aws_instance.faastest.id
  }

  connection {
    host        = aws_eip.faastest_ip.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras enable",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
    ]
  }
}

resource "aws_internet_gateway" "faastest_gw" {
  vpc_id = aws_vpc.faastest.id

  tags = {
    Name = "faastest-gw"
  }
}

resource "aws_route_table" "faastest" {
  vpc_id = aws_vpc.faastest.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.faastest_gw.id
  }

  tags = {
    Name = "faastest-route-table"
  }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.faastest_subnet.id
  route_table_id = aws_route_table.faastest.id
}

#######################################

output "instance_ip" {
  value = aws_eip.faastest_ip.public_ip
}
