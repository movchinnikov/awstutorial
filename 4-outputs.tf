output "instance_public_dns" {
  description = "The public DNS name of the web server."
  value = aws_lb.lb.dns_name
}
