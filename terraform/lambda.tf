# Lambda code zip pacakge
data "archive_file" "lambda_function_file" {
  type = "zip"
  source_file = "../handler.py"
  output_path = "handler.zip"
}

# Lambada function
resource "aws_lambda_function" "restaurant_recommendation" {
  function_name = "restaurant-recommendation"
  filename = data.archive_file.lambda_function_file.output_path
  source_code_hash = data.archive_file.lambda_function_file.output_base64sha256

  runtime = "python3.9"
  handler = "handler.lambda_handler"

  role = aws_iam_role.lambda_execution_role.arn

  environment {
    variables = {
      data_table_name = aws_dynamodb_table.restaurant_data.name
      log_table_name = aws_dynamodb_table.request_log.name
    }
  }
}

# Function url for lambda
resource "aws_lambda_function_url" "restaurant_recommendation" {
  function_name      = aws_lambda_function.restaurant_recommendation.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET","POST"]
    allow_headers     = ["access-control-allow-origin", "access-control-allow-methods", "content-type"]
    expose_headers    = ["access-control-allow-origin", "access-control-allow-methods"]
    max_age           = 86400
  }
}

# Lambda role to access dynamodb table, S3, cloudwatch log group
resource "aws_iam_role" "lambda_execution_role" {
  name = "restaurant_recommendation_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Dynamodb table for restaurants data
resource "aws_dynamodb_table" "restaurant_data" {
  name           = "restaurant_recommendation"
  hash_key       = "restaurant_name"
  billing_mode   = "PAY_PER_REQUEST"
  attribute {
    name = "restaurant_name"
    type = "S"
  }

  attribute {
    name = "cuisine_style"
    type = "S"
  }

  global_secondary_index {
    name               = "cuisine-style-index"
    hash_key           = "cuisine_style"
    projection_type    = "ALL"
  }
}

# Dynamodb table for request/response log
resource "aws_dynamodb_table" "request_log" {
  name           = "Request_response_log"
  hash_key       = "timestamp"
  billing_mode   = "PAY_PER_REQUEST"
  attribute {
    name = "timestamp"
    type = "S"
  }
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda_dynamodb_policy"
  description = "Lambda access to DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = [
          aws_dynamodb_table.restaurant_data.arn,
          "${aws_dynamodb_table.restaurant_data.arn}/index/*",
          aws_dynamodb_table.request_log.arn,
          "${aws_dynamodb_table.request_log.arn}/index/*",
        ]
      },
      {
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:logs:us-east-1:122610493924:*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}
