variable "region" {
  description = "The AWS region in which the resources will be created."
  type = string
  default = "us-east-1"
}

variable "availability_zone" {
  description = "The availability zone where the resources will reside."
  type = string
  default = "a"
}

variable "vpc_id" {
  description = "The ID of the VPC in which to create resources."
  type = string
  default = "vpc-024da8f35cfaf024d"
}

variable "prefix" {
  description = "The prefix to use for the definition of resources."
  type = string
  default = "maxov" #replace on your own
}

variable "instance_type" {
  description = "The type of RDS instance used to create the instance."
  type = string
  default = "db.t3.micro"
}