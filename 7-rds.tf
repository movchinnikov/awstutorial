data "aws_rds_orderable_db_instance" "custom_pgsql" {
  engine = "postgres"
  storage_type = "gp3"
  preferred_instance_classes = ["db.t3.micro"]
}

resource "aws_db_subnet_group" "postgres_rds_subnet_group" {
  name = "${var.prefix}-subnet-group"
  subnet_ids = data.aws_subnets.public_subnets.ids
  description = "RDS subnet group for PostgreSQL"
}

resource "aws_db_instance" "postgres_rds" {
  identifier = "${var.prefix}-postgres-rds"
  engine = data.aws_rds_orderable_db_instance.custom_pgsql.engine
  instance_class = "db.t3.micro"
  allocated_storage = 5
  db_name = "${var.prefix}DB"
  username = "test"
  password = "admin123"
  publicly_accessible = false
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.postgres_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  storage_encrypted = true
  multi_az = true
}

resource "aws_security_group" "postgres_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 5432  # Порт PostgreSQL
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Доступ только внутри VPC
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "postgres_endpoint" {
  description = "The public endpoint for postgres."
  value = aws_db_instance.postgres_rds.endpoint
}