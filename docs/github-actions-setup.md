# GitHub Actions CI/CD Setup Guide

This document provides instructions for setting up the GitHub Actions CI/CD pipeline for the Terragrunt EKS Infrastructure project.

## Required GitHub Secrets

The CI/CD pipeline requires the following secrets to be configured in your GitHub repository:

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key ID | Yes |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret access key | Yes |
| `AWS_REGION` | AWS region for deployment (e.g., us-west-2) | No (defaults to us-west-2) |
| `TERRAFORM_STATE_BUCKET` | S3 bucket for Terraform state | No (uses auto-generated name) |
| `TERRAFORM_LOCK_TABLE` | DynamoDB table for state locking | No (defaults to terraform-locks) |

## Setting Up GitHub Secrets

### Option 1: Using the Setup Script (Recommended)

The easiest way to set up the required AWS credentials and GitHub secrets is to use our provided setup script:

1. Clone the repository and run the setup script:

   ```bash
   git clone https://github.com/santoshbaruah/terragrunt-EKS-infrastructure.git
   cd terragrunt-EKS-infrastructure
   ./scripts/setup-github-actions-iam.sh --bucket-name your-terraform-state-bucket
   ```

2. The script will output the AWS credentials that you need to add to GitHub secrets.

3. Verify the credentials work correctly:

   ```bash
   ./scripts/verify-aws-credentials.sh --access-key ACCESS_KEY_FROM_SCRIPT --secret-key SECRET_KEY_FROM_SCRIPT
   ```

4. Add the credentials to GitHub:
   - Navigate to your GitHub repository
   - Go to **Settings** > **Secrets and variables** > **Actions**
   - Click on **New repository secret**
   - Add each of the required secrets as shown in the script output

### Option 2: Manual Setup

If you prefer to use existing AWS credentials:

1. Navigate to your GitHub repository
2. Go to **Settings** > **Secrets and variables** > **Actions**
3. Click on **New repository secret**
4. Add each of the required secrets:
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: Your AWS access key ID
   - Click **Add secret**
   - Repeat for `AWS_SECRET_ACCESS_KEY`
5. Verify your credentials have the necessary permissions:

   ```bash
   ./scripts/verify-aws-credentials.sh --access-key your_access_key --secret-key your_secret_key
   ```

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

### Common Errors and Solutions

#### "Credentials could not be loaded" Error

If you see an error like:

```text
Error: Credentials could not be loaded, please check your action inputs: Could not load credentials from any providers
```

This indicates that GitHub Actions cannot access your AWS credentials. To fix this:

1. **Verify Secret Names**:
   - Go to your GitHub repository > Settings > Secrets and variables > Actions
   - Confirm that you have secrets named exactly `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (case-sensitive)
   - If they don't exist, create them using the instructions above

2. **Check AWS Credentials Validity**:
   - Verify that the AWS credentials are still valid and not expired
   - Use our verification script to test the credentials locally:

     ```bash
     ./scripts/verify-aws-credentials.sh --access-key your_access_key --secret-key your_secret_key
     ```

   - The script will check if the credentials are valid and have the necessary permissions
   - If the credentials are invalid, create new ones using the setup script

3. **IAM Permissions**:
   - Ensure the IAM user has the necessary permissions listed in the "AWS IAM User Requirements" section
   - When in doubt, run the setup script again to ensure proper permissions

4. **Region Configuration**:
   - Confirm that the AWS region in the workflow file matches the region where your resources should be deployed
   - The region is set in the `env` section at the top of the workflow file

### Additional Troubleshooting Steps

1. **Check Workflow Logs**:
   - Review the detailed logs in the GitHub Actions tab for specific error messages
   - Look for any AWS API errors that might indicate permission issues

2. **Validate Terragrunt Configuration**:
   - Run `terragrunt validate` locally to ensure your configuration is valid
   - Check for any syntax errors in your Terragrunt HCL files

3. **Test with Minimal Configuration**:
   - Try running a minimal workflow that only authenticates with AWS to isolate credential issues
   - Once authentication works, gradually add back the other steps

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Credentials Configuration for GitHub Actions](https://github.com/aws-actions/configure-aws-credentials)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
