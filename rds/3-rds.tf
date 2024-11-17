//aws rds describe-orderable-db-instance-options --engine aurora-postgresql --query "OrderableDBInstanceOptions[*].{Version:EngineVersion,Class:DBInstanceClass}" --output table
data "aws_rds_orderable_db_instance" "aurora_postgresql" {
  engine = "aurora-postgresql"
  engine_version = "14.5"
  instance_class = "db.t3.medium"
}

resource "aws_db_subnet_group" "postgres_rds_subnet_group" {
  name = "${var.prefix}-subnet-group"
  subnet_ids = data.aws_subnets.public_subnets.ids
  description = "RDS subnet group for PostgreSQL"
}

resource "aws_rds_cluster" "postgres_cluster" {
  cluster_identifier = "${var.prefix}-rds-cluster"
  engine = data.aws_rds_orderable_db_instance.aurora_postgresql.engine
  engine_version = data.aws_rds_orderable_db_instance.aurora_postgresql.engine_version
  master_username = "test"
  master_password = "admin123"
  database_name = "${var.prefix}DB"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  db_subnet_group_name = aws_db_subnet_group.postgres_rds_subnet_group.name
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}d"]
  backup_retention_period = 7

  tags = {
    Name = "${var.prefix}-rds-cluster"
  }
}

resource "aws_rds_cluster_instance" "master_instance" {
  identifier = "${var.prefix}-rds-cluster-master"
  cluster_identifier = aws_rds_cluster.postgres_cluster.id
  instance_class = data.aws_rds_orderable_db_instance.aurora_postgresql.instance_class
  engine = data.aws_rds_orderable_db_instance.aurora_postgresql.engine
  engine_version = data.aws_rds_orderable_db_instance.aurora_postgresql.engine_version

  tags = {
    Name = "${var.prefix}-rds-cluster-master"
  }
}

resource "aws_rds_cluster_instance" "replica_instance" {
  identifier = "${var.prefix}-rds-cluster-replica"
  cluster_identifier = aws_rds_cluster.postgres_cluster.id
  instance_class = data.aws_rds_orderable_db_instance.aurora_postgresql.instance_class
  engine = data.aws_rds_orderable_db_instance.aurora_postgresql.engine
  engine_version = data.aws_rds_orderable_db_instance.aurora_postgresql.engine_version

  tags = {
    Name = "${var.prefix}-rds-cluster-replica"
  }
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

output "rds_cluster_endpoint" {
  description = "Endpoint of the PostgreSQL RDS cluster"
  value       = aws_rds_cluster.postgres_cluster.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "Reader endpoint of the PostgreSQL RDS cluster"
  value       = aws_rds_cluster.postgres_cluster.reader_endpoint
}

output "rds_cluster_storage_type" {
  description = "Reader endpoint of the PostgreSQL RDS cluster"
  value       = aws_rds_cluster.postgres_cluster.storage_type
}