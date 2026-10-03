variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 6
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}
