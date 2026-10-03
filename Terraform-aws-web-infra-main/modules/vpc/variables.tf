variable "project_name" {
  description = "Όνομα project (χρησιμοποιείται σε tags)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block για το VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Λίστα availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks για public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks για private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Ενεργοποίηση NAT Gateway για private subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Κοινά tags για όλα τα resources"
  type        = map(string)
  default     = {}
}
