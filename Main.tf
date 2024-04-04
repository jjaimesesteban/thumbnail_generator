//AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" // Define the AWS provider source
      version = "4.36.1"        // Define the minimum version of the AWS provider
    }
    archive = {
      source  = "hashicorp/archive" // Define the Archive provider source
      version = "~> 2.2.0"          // Define the minimum version of the Archive provider
    }
  }
  required_version = "~> 1.0" // Define the minimum required Terraform version
}

provider "aws" {
  region = var.aws_region // Configure the AWS region using the defined variable
}

//Original and Thumbnail S3 bucket
resource "aws_s3_bucket" "thumbnail_original_image_bucket" {
  bucket = "jjaimesesteban-original-image-bucket" // Create an S3 bucket for original images
}

resource "aws_s3_bucket" "thumbnail_image_bucket" {
  bucket = "jjaimesesteban-thumbnail-image-bucket" // Create an S3 bucket for thumbnails
}

//Setting the policy of Get (Original) and Put object (Thumbnail)
resource "aws_iam_policy" "thumbnail_s3_policy" {
  name = "thumbnail_s3_policy" // Name of the IAM policy
  policy = jsonencode({        // Define the IAM policy in JSON format
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : "s3:GetObject", // Allow action to get objects in the original image bucket
      "Resource" : "arn:aws:s3:::jjaimesesteban-original-image-bucket/*"
      }, {
      "Effect" : "Allow",
      "Action" : "s3:PutObject", // Allow action to put objects in the thumbnail bucket
      "Resource" : "arn:aws:s3:::jjaimesesteban-thumbnail-image-bucket/*"
    }]
  })
}

//Creating S3 bucket policy for allowing Lambda function to access objects
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.thumbnail_input_image_bucket_hg.id // Specify the ID of the S3 bucket

  policy = jsonencode({ // Encode the policy in JSON format
    Version = "2012-10-17", // Specify the policy version
    Statement = [ // Define an array of policy statements
      {
        Effect = "Allow", // Specify the effect of the statement
        Principal = { // Specify the principal entity
          Service = "lambda.amazonaws.com" // Specify the Lambda service principal
        },
        Action = "s3:GetObject", // Define the allowed action
        Resource = "arn:aws:s3:::jjaimesesteban-original-image-bucket/*" // Specify the ARN of the S3 bucket and objects
      }
    ]
  })
}


//Lambda IAM Role to assume the role
resource "aws_iam_role" "thumbnail_lambda_role" {
  name = "thumbnail_lambda_role" // Name of the IAM role for Lambda function
  assume_role_policy = jsonencode({ // Define the assume IAM role policy
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "lambda.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

//IAM Policy Attachment, role for s3 and role for lambda
resource "aws_iam_policy_attachment" "thumbnail_role_s3_policy_attachment" {
  name       = "thumbnail_role_s3_policy_attachment" // Name of the IAM policy attachment for S3 role
  roles      = [aws_iam_role.thumbnail_lambda_role.name] // Associate IAM policy to Lambda role
  policy_arn = aws_iam_policy.thumbnail_s3_policy.arn // ARN of IAM policy for S3 access
}
resource "aws_iam_policy_attachment" "thumbnail_role_lambda_policy_attachment" {
  name       = "thumbnail_role_lambda_policy_attachment" // Name of the IAM policy attachment for Lambda role
  roles      = [aws_iam_role.thumbnail_lambda_role.name] // Associate IAM policy to Lambda role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" // ARN of basic Lambda IAM policy
}
data "archive_file" "thumbnail_lambda_source_archive" {
    type        = "zip"
    source_dir  = "${path.module}/src"
    output_path = "${path.module}/my-lambda-code.zip"
  }

//Configuration to zip the lambda file to upload “my-lambda-code.zip”
resource "aws_lambda_function" "thumbnail_lambda" {
  function_name = "thumbnail_generation_lambda" // Name of the Lambda function
  filename      = "${path.module}/my-lambda-code.zip" // Path to the ZIP file containing Lambda function code

  runtime     = "python3.9" // Python version used by Lambda function
  handler     = "lambda.lambda_handler" // Entry point of the Lambda function
  memory_size = 256 // Memory size allocated to the Lambda function

  source_code_hash = data.archive_file.thumbnail_lambda_source_archive.output_base64sha256 // Hash of the Lambda function source code

  role = aws_iam_role.thumbnail_lambda_role.arn // ARN of IAM role assigned to Lambda function

}

//Setting lambda permission to Thumbnail bucket to put the thumbnail.
resource "aws_lambda_permission" "thumbnail_allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket" // ID of the Lambda permission statement
  action        = "lambda:InvokeFunction" // Allowed action for the Lambda function
  function_name = aws_lambda_function.thumbnail_lambda.arn // ARN of the Lambda function
  principal     = "s3.amazonaws.com" // Principal entity that can invoke the Lambda function
  source_arn    = aws_s3_bucket.thumbnail_original_image_bucket.arn // ARN of the S3 bucket triggering the Lambda function
}

resource "aws_s3_bucket_notification" "thumbnail_notification" {
  bucket = aws_s3_bucket.thumbnail_original_image_bucket.id // ID of the S3 bucket

  lambda_function { // Configure Lambda function as notification destination
    lambda_function_arn = aws_lambda_function.thumbnail_lambda.arn // ARN of the Lambda function
    events              = ["s3:ObjectCreated:*"] // Events triggering the Lambda function
  }

  depends_on = [ // Resource dependencies for S3 bucket notification
    aws_lambda_permission.thumbnail_allow_bucket
  ]
}

//Creation of CloudWatch log group for logging purpose and monitoring traces.
resource "aws_cloudwatch_log_group" "thumbnail_cloudwatch" {
  name = "/aws/lambda/${aws_lambda_function.thumbnail_lambda.function_name}"

  retention_in_days = 30
}