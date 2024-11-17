output "instance_public_dns" {
  description = "The public DNS name of the web server."
  value = aws_lb.lb.dns_name
}

output "rds_cluster_public_dns" {
  description = "The public DNS name of the rds cluster."
  value = data.aws_rds_cluster.postgres_cluster.endpoint
}