provider "aws" {
  region = var.aws_region
}

# ─── Default VPC & Subnet ─────────────────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ─── Security Group ───────────────────────────────────────────────────────────
resource "aws_security_group" "zomato_sg" {
  name        = "zomato-devsecops-sg"
  description = "Zomato DevSecOps - Jenkins, SonarQube, App"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "zomato-devsecops-sg"
    Project = "zomato-devsecops"
  }
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────
resource "tls_private_key" "zomato_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "zomato_key" {
  key_name   = var.key_name
  public_key = tls_private_key.zomato_key.public_key_openssh
}

resource "local_file" "zomato_pem" {
  content         = tls_private_key.zomato_key.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────
resource "aws_instance" "jenkins_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.zomato_key.key_name
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.zomato_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = base64encode(file("${path.module}/userdata.sh"))

  tags = {
    Name    = "zomato-jenkins-server"
    Project = "zomato-devsecops"
  }
}
