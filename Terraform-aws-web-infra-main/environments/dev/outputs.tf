output "alb_dns_name" {
  description = "Το URL που θα ανοίξεις στο browser"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
