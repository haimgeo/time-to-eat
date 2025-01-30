# Tempalte index.html file with lambda function url and pic url
data "template_file" "index_html" {
  template = "${file("${path.cwd}/../index_html.tpl")}"
  vars = {
    bucket_id    = "${aws_s3_bucket.time_to_eat.id}"
    function_url = "${aws_lambda_function_url.restaurant_recommendation.function_url}"
  }
}

# S3 static web site bucket
resource "aws_s3_bucket" "time_to_eat" {
  bucket = "time-to-eat"
  force_destroy = true
}
# S3 static web site config
resource "aws_s3_bucket_website_configuration" "time_to_eat" {
  bucket = aws_s3_bucket.time_to_eat.id
  index_document {
    suffix = "index.html"
  }
}
# Bucket policy
resource "aws_s3_bucket_policy" "time_to_eat_public_read" {
  bucket = aws_s3_bucket.time_to_eat.id
  depends_on = [
    aws_s3_bucket_public_access_block.time_to_eat
  ]
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
   "Principal": "*",
      "Action": [ "s3:GetObject" ],
      "Resource": [
        "${aws_s3_bucket.time_to_eat.arn}",
        "${aws_s3_bucket.time_to_eat.arn}/*"
      ]
    }
  ]
}
EOF
}

# Upload templated index.html to bucket
resource "aws_s3_bucket_object" "index_html" {
  bucket        = aws_s3_bucket.time_to_eat.id
  content       = data.template_file.index_html.rendered
  key           = "index.html"
  content_type  = "text/html"
}

# Upload pic to bucket
resource "aws_s3_object" "pic" {
  bucket        = aws_s3_bucket.time_to_eat.id
  key           = "veg.jpg"
  source        = "../veg.jpg"
  source_hash = filemd5("../veg.jpg")
  content_type = "image/jpeg"
}

# Set bucket public access
resource "aws_s3_bucket_public_access_block" "time_to_eat" {
  bucket = aws_s3_bucket.time_to_eat.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}