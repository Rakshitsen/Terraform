resource "aws_s3_bucket" "s3b" {
  bucket = "aajamerescootermeaajana"

  tags = {
    Name = "bucket"
  }
}

