variable "project_name" {
  description = "Όνομα project, χρησιμοποιείται στο όνομα του IAM role"
  type        = string
  default     = "myapp"
}

variable "github_org" {
  description = "Το GitHub username ή organization σου, π.χ. \"johndoe\""
  type        = string
}

variable "github_repo" {
  description = "Το όνομα του repository, π.χ. \"aws-vpc-alb-autoscaling-terraform\""
  type        = string
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}
