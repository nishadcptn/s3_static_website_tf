resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

resource "aws_s3_bucket_acl" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject","s3:PutObject"]
        Resource = [
          aws_s3_bucket.s3_bucket.arn,
          "${aws_s3_bucket.s3_bucket.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_object" "object_www" {
  depends_on   = [aws_s3_bucket.s3_bucket]
  for_each     = fileset("${path.root}", "www/*")
  bucket       = var.bucket_name
  key          = basename(each.value)
  source       = each.value
  etag         = filemd5("${each.value}")
  content_type = "text/html"
  acl          = "public-read"
}



variable "content_types" {
  default = {
    ".html" = "text/html",
    ".css"  = "text/css",
    ".js"   = "application/javascript",
    ".png"  = "image/png",
    ".jpg"  = "image/jpeg",
    ".jpeg" = "image/jpeg",
    ".gif"  = "image/gif",
    ".svg"  = "image/svg+xml"
    # Add more file extensions and their corresponding content types as needed
  }
}


resource "aws_s3_object" "object_assets" {
  depends_on = [aws_s3_bucket.s3_bucket]
  for_each   = fileset(path.module, "www/**/*")
  bucket     = var.bucket_name
  key        = each.value
  source     = each.value
  etag       = filemd5("${each.value}")
  content_type = lookup(var.content_types, substr(each.value, -4, 4), "application/octet-stream")
  acl        = "public-read"
}