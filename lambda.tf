# Create S3 Bucket for storing CSV
resource "aws_s3_bucket" "csv_cities" {
  bucket = "csv-cities-example-bucket"
  acl    = "private"

  tags = {
    Name        = "CSV Premier League Bucket"
    Environment = "Development"
  }
}

# Use open source module for easier management of lambda function

module "lambda_function_externally_managed_package" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "csv-importer-s3-cities"
  description   = "Lambda that imports CSV from s3 and stores in DynamoDB"
  handler       = "index"
  runtime       = "nodejs14.x"

  create_package         = false
  local_existing_package = var.csv_importer_filename
  create_current_version_allowed_triggers = false

  ignore_source_code_hash = false

  allowed_triggers = {
    ScanAmiRule = {
      principal  = "s3.amazonaws.com"
      source_arn = aws_s3_bucket.csv_cities.arn
    }
  }
}

# Create DynamoDB table 
resource "aws_dynamodb_table" "cities" {
  name = "Cities"
  read_capacity  = 20
  write_capacity = 20

  hash_key       = "Date"
  range_key      = "HomeTeam"

  attribute {
    name = "Date"
    type = "N"
  }

  attribute {
    name = "HomeTeam"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-cities"
    Environment = "Development"
  }
}
