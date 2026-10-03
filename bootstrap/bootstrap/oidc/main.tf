############################################
# GitHub OIDC federation
#
# Δημιουργεί έναν IAM Role που το GitHub Actions
# μπορεί να "υποδυθεί" χωρίς static AWS keys.
# Τρέχεται μία φορά, ξεχωριστά από τα dev/prod
# environments (δικό του state, τοπικό).
############################################

data "aws_caller_identity" "current" {}

# Το thumbprint είναι σταθερό, ανήκει στο GitHub OIDC endpoint
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        # Περιορίζει ποιος μπορεί να πάρει τον ρόλο:
        # μόνο workflows από το συγκεκριμένο repo, στο branch main
        # (και pull requests, ώστε να δουλεύει το `terraform plan` σε PRs)
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
            "repo:${var.github_org}/${var.github_repo}:pull_request"
          ]
        }
      }
    }]
  })
}

# Δικαιώματα που χρειάζεται το pipeline για να διαχειρίζεται
# το infrastructure που ορίζει αυτό το project (VPC, ALB, EC2,
# state bucket, lock table). Σε πραγματικό production θα τα
# περιόριζες ακόμα περισσότερο ανά resource/ARN.
resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "elb" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy_attachment" "autoscaling" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_state" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamodb_lock" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Το Auto Scaling Group χρειάζεται ένα service-linked role,
# και το ec2 module αφήνει το AWS provider να διαχειρίζεται IAM
# μόνο για τα δικά του instance roles -- εδώ δίνουμε στο pipeline
# δικαίωμα να τα φτιάχνει.
resource "aws_iam_role_policy_attachment" "iam_limited" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}
