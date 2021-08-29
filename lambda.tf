resource "aws_s3_bucket" "csv_cities" {
  bucket = "csv-cities-example-bucket"
  acl    = "private"

  tags = {
    Name        = "CSV Premier League Bucket"
    Environment = "Development"
  }
}

resource "aws_iam_role" "lambda_csv_importer" {
  name = "lambda-csv-importer-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "s3.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

variable "csv_importer_filename" {
  default = "csv_importer.zip"
}

resource "aws_lambda_function" "csv_importer" {
  filename      = var.csv_importer_filename
  function_name = "csv_importer_cities"
  role          = aws_iam_role.lambda_csv_importer.arn
  handler       = "index"

  source_code_hash = filebase64sha256(var.csv_importer_filename)

  runtime     = "nodejs14.x"
  timeout     = "900"
  memory_size = "3008"

  environment {
    variables = {
      BucketName : aws_s3_bucket.csv_cities.bucket,
      FileName : "cities.csv",
      DynamoDBTableName : aws_dynamodb_table.premier_league.name
    }
  }
}

resource "aws_dynamodb_table" "premier_league" {
  name = "PremierLeague"
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
    Name        = "dynamodb-table-premier-league"
    Environment = "Development"
  }
}
