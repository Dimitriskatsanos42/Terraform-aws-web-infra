#!/bin/bash
############################################################
# Τρέξε αυτό ΜΙΑ φορά, πριν το πρώτο terraform init,
# για να φτιάξεις το S3 bucket και το DynamoDB table
# που θα κρατάνε το remote state.
#
# Χρήση:
#   ./bootstrap.sh <bucket-name> <aws-region>
# π.χ.
#   ./bootstrap.sh myapp-terraform-state eu-central-1
############################################################
set -e

BUCKET_NAME=${1:?"Δώσε όνομα bucket, π.χ. ./bootstrap.sh myapp-terraform-state eu-central-1"}
REGION=${2:-eu-central-1}
TABLE_NAME="terraform-locks"

echo ">> Δημιουργία S3 bucket: $BUCKET_NAME στο $REGION"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

echo ">> Ενεργοποίηση versioning"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo ">> Ενεργοποίηση encryption"
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

echo ">> Block public access"
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo ">> Δημιουργία DynamoDB table για locking: $TABLE_NAME"
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "✅ Έτοιμο! Τώρα ενημέρωσε τα backend.tf (dev & prod) με:"
echo "   bucket = \"$BUCKET_NAME\""
echo "   region = \"$REGION\""
