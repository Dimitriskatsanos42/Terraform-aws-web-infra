output "role_arn" {
  description = "Αυτό το ARN πάει στο GitHub ως repository variable AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
