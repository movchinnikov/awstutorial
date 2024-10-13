output "instance_public_dns" {
  description = "The public DNS name of the web server."
  value = aws_instance.my_first_instance.public_dns
}