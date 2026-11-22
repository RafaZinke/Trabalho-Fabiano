data "aws_s3_bucket" "pacotes" {
  bucket = "trabalho-fabiano-pacotes-78c742d5fab4b9ca4a481405fd"
}

resource "aws_s3_bucket_public_access_block" "pacotes" {
  bucket = data.aws_s3_bucket.pacotes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "pacotes" {
  bucket = data.aws_s3_bucket.pacotes.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pacotes" {
  bucket = data.aws_s3_bucket.pacotes.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "bucket_pacotes" {
  value = data.aws_s3_bucket.pacotes.id
}