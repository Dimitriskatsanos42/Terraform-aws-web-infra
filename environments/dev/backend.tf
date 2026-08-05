############################################
# Remote state στο S3 με DynamoDB locking
# ΣΗΜΕΙΩΣΗ: Το bucket και το DynamoDB table
# πρέπει να υπάρχουν ΠΡΙΝ το `terraform init`.
# Δες README.md -> "Bootstrap remote state".
############################################

terraform {
  backend "s3" {
    bucket         = "CHANGE-ME-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
