# GitHub Actions CI/CD for Terragrunt EKS Infrastructure

This directory contains the GitHub Actions workflows for deploying and managing the Terragrunt EKS infrastructure.

## AWS Authentication Setup

The CI/CD pipeline requires AWS credentials to interact with your AWS account. There are two options for configuring AWS authentication:

### Option 1: IAM User (Long-lived credentials)

This is simpler to set up but less secure for production environments.

1. Create an IAM user with appropriate permissions:
   - Create a new IAM user in your AWS account
   - Attach policies that grant permissions for EKS, EC2, VPC, IAM, and other resources needed by your Terraform/Terragrunt code
   - Example minimum permissions: `AmazonEKSClusterPolicy`, `AmazonVPCFullAccess`, and custom policies for other resources

2. Generate access keys for the IAM user:
   - In the AWS Management Console, go to IAM > Users > [Your User] > Security credentials
   - Create a new access key
   - Download or copy the access key ID and secret access key

3. Add the credentials as GitHub repository secrets:
   - Go to your GitHub repository > Settings > Secrets and variables > Actions
   - Add the following secrets:
     - `AWS_ACCESS_KEY_ID`: Your IAM user's access key ID
     - `AWS_SECRET_ACCESS_KEY`: Your IAM user's secret access key

### Option 2: OIDC (OpenID Connect) - Recommended for production

This is more secure as it uses short-lived credentials and doesn't require storing long-lived access keys.

1. Configure OIDC between GitHub and AWS:
   - Follow the instructions in the [GitHub documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
   - Create an IAM OIDC identity provider for GitHub Actions

2. Create an IAM role with appropriate permissions:
   - Create a new IAM role
   - Attach the necessary policies (similar to those for the IAM user)
   - Configure the trust relationship to allow GitHub Actions to assume the role:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/terragrunt-EKS-infrastructure:*"
           }
         }
       }
     ]
   }
   ```

3. Add the role ARN as a GitHub repository secret:
   - Go to your GitHub repository > Settings > Secrets and variables > Actions
   - Add the following secret:
     - `AWS_ROLE_TO_ASSUME`: The ARN of the IAM role (e.g., `arn:aws:iam::123456789012:role/GitHubActionsRole`)

4. Update the workflow file:
   - In the `.github/workflows/terragrunt.yml` file, uncomment the OIDC configuration in the "Configure AWS credentials" steps
   - Comment out the IAM user credentials configuration

## Troubleshooting AWS Credentials Issues

If you encounter AWS credentials errors in your GitHub Actions workflow:

1. Verify that the secrets are correctly set in your GitHub repository
2. Check that the IAM user or role has the necessary permissions
3. For OIDC:
   - Ensure the OIDC provider is correctly configured
   - Verify the trust relationship conditions match your repository
4. Check the AWS region specified in the workflow
5. Try running the `aws sts get-caller-identity` command locally with the same credentials to verify they work

## Workflow Usage

The workflow can be triggered in several ways:

- **Automatically**: On push or pull request to the main branch
- **Manually**: Using the GitHub Actions workflow dispatch with the following inputs:
  - Environment: `dev`, `staging`, or `prod`
  - Action: `plan`, `apply`, or `destroy`

### Manual Execution

1. Go to the Actions tab in your GitHub repository
2. Select the "Terragrunt CI/CD" workflow
3. Click "Run workflow"
4. Select the branch, environment, and action
5. Click "Run workflow"

## Security Best Practices

1. Use OIDC instead of long-lived credentials when possible
2. Limit the permissions of the IAM user or role to only what is necessary
3. Regularly rotate IAM user access keys if using Option 1
4. Use environment protection rules for production environments
5. Review the workflow logs for any sensitive information before sharing
