## Thumbnail Generator Project

### Objective:
The Thumbnail Generator project aims to automate the generation of thumbnails for images uploaded to an AWS S3 bucket. It utilizes AWS Lambda functions triggered by S3 events to create thumbnails for images stored in the designated bucket.

### Features:
- Automatically generates thumbnails for images uploaded to the specified S3 bucket.
- Utilizes AWS Lambda functions written in Python.
- Integrates with AWS CloudWatch for monitoring and logging.

### Components:
1. **AWS S3 Bucket**: Stores original images and generated thumbnails.
2. **AWS Lambda Function**: Responsible for generating thumbnails upon image upload events.
3. **AWS CloudWatch Logs**: Logs events and errors for monitoring and troubleshooting.
4. **Terraform Configuration**: Infrastructure-as-Code (IaC) using Terraform to provision and manage AWS resources.

### How to Use:
1. Clone the repository.
2. Customize the Terraform configuration to match your AWS environment.
3. Deploy the infrastructure using Terraform.
4. Upload images to the designated S3 bucket to trigger thumbnail generation.
5. Monitor CloudWatch logs for processing details and errors.

### Dependencies:
- Terraform
- AWS CLI
- Python (for custom Lambda function)

### Author:
Jaime Jaimes
