#!/bin/bash
# Script to create an IAM user for GitHub Actions with the necessary permissions

set -e

# Default values
IAM_USER_NAME="github-actions-terragrunt"
AWS_REGION="us-west-2"
STATE_BUCKET_NAME=""
LOCK_TABLE_NAME="terraform-locks"

# Display help
function show_help {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -u, --user-name NAME       IAM user name (default: github-actions-terragrunt)"
    echo "  -r, --region REGION        AWS region (default: us-west-2)"
    echo "  -b, --bucket-name NAME     S3 bucket name for Terraform state (required)"
    echo "  -t, --table-name NAME      DynamoDB table name for state locking (default: terraform-locks)"
    echo "  -h, --help                 Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -u|--user-name)
            IAM_USER_NAME="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -b|--bucket-name)
            STATE_BUCKET_NAME="$2"
            shift 2
            ;;
        -t|--table-name)
            LOCK_TABLE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Check if required parameters are provided
if [ -z "$STATE_BUCKET_NAME" ]; then
    echo "Error: S3 bucket name is required"
    show_help
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

echo "Creating IAM user for GitHub Actions..."
echo "User name: $IAM_USER_NAME"
echo "AWS region: $AWS_REGION"
echo "Terraform state bucket: $STATE_BUCKET_NAME"
echo "DynamoDB lock table: $LOCK_TABLE_NAME"
echo

# Create IAM user
echo "Creating IAM user..."
aws iam create-user --user-name "$IAM_USER_NAME" || echo "User already exists, continuing..."

# Create S3 bucket for Terraform state if it doesn't exist
echo "Creating S3 bucket for Terraform state (if it doesn't exist)..."
if ! aws s3api head-bucket --bucket "$STATE_BUCKET_NAME" 2>/dev/null; then
    aws s3api create-bucket \
        --bucket "$STATE_BUCKET_NAME" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$STATE_BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$STATE_BUCKET_NAME" \
        --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
fi

# Create DynamoDB table for state locking if it doesn't exist
echo "Creating DynamoDB table for state locking (if it doesn't exist)..."
if ! aws dynamodb describe-table --table-name "$LOCK_TABLE_NAME" --region "$AWS_REGION" 2>/dev/null; then
    aws dynamodb create-table \
        --table-name "$LOCK_TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION"
fi

# Create IAM policy for Terraform state management
echo "Creating IAM policy for Terraform state management..."
POLICY_NAME="${IAM_USER_NAME}-terraform-state-policy"
POLICY_DOCUMENT='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::'$STATE_BUCKET_NAME'",
                "arn:aws:s3:::'$STATE_BUCKET_NAME'/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:'$AWS_REGION':'$(aws sts get-caller-identity --query Account --output text)':table/'$LOCK_TABLE_NAME'"
        }
    ]
}'

# Create or update the policy
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
if [ -z "$POLICY_ARN" ]; then
    POLICY_ARN=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "$POLICY_DOCUMENT" --query Policy.Arn --output text)
else
    aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document "$POLICY_DOCUMENT" --set-as-default
fi

# Attach policies to the IAM user
echo "Attaching policies to the IAM user..."
aws iam attach-user-policy --user-name "$IAM_USER_NAME" --policy-arn "$POLICY_ARN"
aws iam attach-user-policy --user-name "$IAM_USER_NAME" --policy-arn "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
aws iam attach-user-policy --user-name "$IAM_USER_NAME" --policy-arn "arn:aws:iam::aws:policy/AmazonVPCFullAccess"

# Create access key for the IAM user
echo "Creating access key for the IAM user..."
ACCESS_KEY=$(aws iam create-access-key --user-name "$IAM_USER_NAME" --query AccessKey --output json)

# Extract access key ID and secret access key
ACCESS_KEY_ID=$(echo "$ACCESS_KEY" | jq -r .AccessKeyId)
SECRET_ACCESS_KEY=$(echo "$ACCESS_KEY" | jq -r .SecretAccessKey)

echo
echo "===== GitHub Actions IAM User Created ====="
echo "Add the following secrets to your GitHub repository:"
echo
echo "AWS_ACCESS_KEY_ID: $ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $SECRET_ACCESS_KEY"
echo "AWS_REGION: $AWS_REGION"
echo "TERRAFORM_STATE_BUCKET: $STATE_BUCKET_NAME"
echo "TERRAFORM_LOCK_TABLE: $LOCK_TABLE_NAME"
echo
echo "For security reasons, these credentials will not be shown again."
echo "Make sure to save them in a secure location."
