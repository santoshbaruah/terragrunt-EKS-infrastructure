# GitHub Actions CI/CD Setup Guide

This document provides instructions for setting up the GitHub Actions CI/CD pipeline for the Terragrunt EKS Infrastructure project.

## Required GitHub Secrets

The CI/CD pipeline requires the following secrets to be configured in your GitHub repository:

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key ID | Yes |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret access key | Yes |

## Setting Up GitHub Secrets

1. Navigate to your GitHub repository
2. Go to **Settings** > **Secrets and variables** > **Actions**
3. Click on **New repository secret**
4. Add each of the required secrets:
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: Your AWS access key ID
   - Click **Add secret**
   - Repeat for `AWS_SECRET_ACCESS_KEY`

![GitHub Secrets Setup](images/github-secrets-setup.png)

## AWS IAM User Requirements

The AWS IAM user associated with the provided credentials should have the following permissions:

1. **Minimum Required Permissions**:
   - `AmazonEKSClusterPolicy`
   - `AmazonVPCFullAccess`
   - `AmazonS3FullAccess` (for Terraform state)
   - `AmazonDynamoDBFullAccess` (for state locking)

2. **Creating an IAM User with Required Permissions**:

   We've provided a helper script to automate the creation of an IAM user with the necessary permissions:

   ```bash
   # Clone the repository if you haven't already
   git clone https://github.com/santoshbaruah/terragrunt-EKS-infrastructure.git
   cd terragrunt-EKS-infrastructure

   # Run the setup script
   ./scripts/setup-github-actions-iam.sh --bucket-name your-terraform-state-bucket
   ```

   The script will:
   - Create an IAM user for GitHub Actions
   - Create an S3 bucket for Terraform state (if it doesn't exist)
   - Create a DynamoDB table for state locking (if it doesn't exist)
   - Attach the necessary policies to the IAM user
   - Generate access keys and display them for you to add to GitHub secrets

   You can customize the script with additional options:

   ```bash
   Usage: ./scripts/setup-github-actions-iam.sh [options]
   Options:
     -u, --user-name NAME       IAM user name (default: github-actions-terragrunt)
     -r, --region REGION        AWS region (default: us-west-2)
     -b, --bucket-name NAME     S3 bucket name for Terraform state (required)
     -t, --table-name NAME      DynamoDB table name for state locking (default: terraform-locks)
     -h, --help                 Show this help message
   ```

   The script will output the access key ID and secret access key that you'll need to add to GitHub secrets.

## Verifying the Setup

After setting up the secrets, you can verify the setup by:

1. Going to the **Actions** tab in your GitHub repository
2. Selecting the **Terragrunt CI/CD** workflow
3. Clicking on **Run workflow** > **Run workflow**

The workflow should now run successfully without the credentials error.

## Troubleshooting

If you continue to experience issues with the GitHub Actions workflow:

1. **Check Secret Names**: Ensure the secret names match exactly what's in the workflow file
2. **Verify AWS Credentials**: Confirm the AWS credentials are valid and have the necessary permissions
3. **Check AWS Region**: Make sure the AWS region specified in the workflow matches where your resources should be deployed
4. **Review Workflow Logs**: Check the detailed logs in the GitHub Actions tab for specific error messages

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Credentials Configuration for GitHub Actions](https://github.com/aws-actions/configure-aws-credentials)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
