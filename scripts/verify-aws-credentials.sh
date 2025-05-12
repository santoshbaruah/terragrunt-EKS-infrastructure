#!/bin/bash
# Script to verify AWS credentials for GitHub Actions

set -e

# Default values
AWS_REGION="us-west-2"
ACCESS_KEY=""
SECRET_KEY=""
VERIFY_ONLY=false

# Display help
function show_help {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -k, --access-key KEY       AWS access key ID"
    echo "  -s, --secret-key KEY       AWS secret access key"
    echo "  -r, --region REGION        AWS region (default: us-west-2)"
    echo "  -v, --verify-only          Only verify credentials, don't check permissions"
    echo "  -h, --help                 Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -k|--access-key)
            ACCESS_KEY="$2"
            shift 2
            ;;
        -s|--secret-key)
            SECRET_KEY="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -v|--verify-only)
            VERIFY_ONLY=true
            shift
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
if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
    echo "Error: AWS access key and secret key are required"
    show_help
fi

# Temporary AWS credentials file
AWS_CREDS_FILE=$(mktemp)
trap "rm -f $AWS_CREDS_FILE" EXIT

# Set up AWS credentials
cat > "$AWS_CREDS_FILE" <<EOF
[default]
aws_access_key_id = $ACCESS_KEY
aws_secret_access_key = $SECRET_KEY
region = $AWS_REGION
EOF

echo "Verifying AWS credentials..."
if AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDS_FILE" aws sts get-caller-identity; then
    echo "✅ AWS credentials are valid!"
    
    # Extract account ID for display
    ACCOUNT_ID=$(AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDS_FILE" aws sts get-caller-identity --query Account --output text)
    echo "Account ID: $ACCOUNT_ID"
    
    if [ "$VERIFY_ONLY" = false ]; then
        echo
        echo "Checking required permissions for GitHub Actions..."
        
        # Check S3 permissions
        echo "Testing S3 permissions..."
        if AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDS_FILE" aws s3 ls >/dev/null 2>&1; then
            echo "✅ S3 list permission confirmed"
        else
            echo "❌ Missing S3 permissions"
        fi
        
        # Check DynamoDB permissions
        echo "Testing DynamoDB permissions..."
        if AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDS_FILE" aws dynamodb list-tables >/dev/null 2>&1; then
            echo "✅ DynamoDB list permission confirmed"
        else
            echo "❌ Missing DynamoDB permissions"
        fi
        
        # Check EKS permissions
        echo "Testing EKS permissions..."
        if AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDS_FILE" aws eks list-clusters >/dev/null 2>&1; then
            echo "✅ EKS list permission confirmed"
        else
            echo "❌ Missing EKS permissions"
        fi
        
        # Check VPC permissions
        echo "Testing VPC permissions..."
        if AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDS_FILE" aws ec2 describe-vpcs >/dev/null 2>&1; then
            echo "✅ VPC list permission confirmed"
        else
            echo "❌ Missing VPC permissions"
        fi
    fi
    
    echo
    echo "These credentials should work with GitHub Actions."
    echo "Add them as repository secrets with the following names:"
    echo "  - AWS_ACCESS_KEY_ID"
    echo "  - AWS_SECRET_ACCESS_KEY"
else
    echo "❌ AWS credentials verification failed!"
    echo "Please check that your access key and secret key are correct."
fi
