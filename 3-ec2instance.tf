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

data "aws_ami" "amazon_linux" {
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

data "aws_subnet" "public_subnet_az_a" {
  filter {
    name = "vpc-id"
    values = ["${var.vpc_id}"]
  }

  filter {
    name = "availability-zone"
    values = ["${var.region}${var.availability_zone}"]
  }
}

resource "aws_instance" "my_first_instance" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "${var.instance_type}"
  subnet_id = data.aws_subnet.public_subnet_az_a.id
  key_name = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.sg.id]
  user_data = file("${path.module}/user_data.sh")
  
  tags = {
    Name = "${var.prefix}-first-instance"
  }
}