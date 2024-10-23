resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name = "${var.prefix}-pem"
  public_key = tls_private_key.private_key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.private_key.private_key_pem}' > ~/.ssh/${var.prefix}-pem.pem && chmod 400 ~/.ssh/${var.prefix}-pem.pem"
    
  }
}

data "aws_ami" "ami_amazon_linux" {
  most_recent = true

  filter {
    name = "name"
    values = ["${var.ami_name}"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.ami_owner}"] # Amazon
}

data "aws_subnets" "public_subnets" {
  filter {
    name = "vpc-id"
    values = ["${var.vpc_id}"]
  }

  filter {
    name = "availability-zone"
    values = ["${var.region}a", "${var.region}b"]
  }
}