data "aws_rds_orderable_db_instance" "custom_pgsql" {
  engine = "postgres"
  storage_type = "gp3"
  preferred_instance_classes = [var.instance_type]
  license_model = "postgresql-license"
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
  storage_type = data.aws_rds_orderable_db_instance.custom_pgsql.storage_type
  allocated_storage = 20
  db_name = "${var.prefix}DB"
  username = "test"
  password = "admin123"
  publicly_accessible = true
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.postgres_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  storage_encrypted = true
  multi_az = true
  license_model = data.aws_rds_orderable_db_instance.custom_pgsql.license_model
}

resource "aws_security_group" "postgres_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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