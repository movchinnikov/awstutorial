data "aws_subnets" "public_subnets" {
  filter {
    name = "vpc-id"
    values = ["${var.vpc_id}"]
  }

  filter {
    name = "availability-zone"
    values = ["${var.region}a", "${var.region}b", "${var.region}d"]
  }
}