locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_name          = "${var.project_name}-${var.environment}"
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  enable_nat_gateway    = true
  tags                  = local.tags
}

module "alb" {
  source = "../../modules/alb"

  project_name      = "${var.project_name}-${var.environment}"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  tags              = local.tags
}

module "ec2" {
  source = "../../modules/ec2"

  project_name           = "${var.project_name}-${var.environment}"
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  alb_security_group_id  = module.alb.alb_security_group_id
  target_group_arn       = module.alb.target_group_arn
  instance_type          = var.instance_type
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_desired_capacity
  tags                   = local.tags
}
