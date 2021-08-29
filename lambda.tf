resource "aws_s3_bucket" "csv_premier_league" {
  bucket = "csv-premier-league-bucket"
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
  function_name = "csv_premier_league_importer"
  role          = aws_iam_role.lambda_csv_importer.arn
  handler       = "index.lambda_handler"

  source_code_hash = filebase64sha256(var.csv_importer_filename)

  runtime     = "python3.7"
  timeout     = "900"
  memory_size = "3008"

  environment {
    variables = {
      BucketName : aws_s3_bucket.csv_premier_league.bucket,
      FileName : "premier_league.csv",
      DynamoDBTableName : ""
    }
  }
}
