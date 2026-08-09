provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "app_data" {
  bucket = "devsecops-demo-data"

  tags = {
    Environment = "staging"
    Project     = "devsecops-pipeline"
  }
}

# ✅ FIX: Thêm encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# ✅ FIX: Thêm versioning
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ✅ FIX: Block public access
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket                  = aws_s3_bucket.app_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ✅ FIX: Thêm logging
resource "aws_s3_bucket_logging" "app_data" {
  bucket        = aws_s3_bucket.app_data.id
  target_bucket = aws_s3_bucket.app_data.id
  target_prefix = "log/"
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for app"

  # ✅ FIX: SSH chỉ cho IP cụ thể, không phải 0.0.0.0/0
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "SSH from internal network only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # ✅ FIX: Bật monitoring
  monitoring = true

  # ✅ FIX: Bắt buộc IMDSv2
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "devsecops-app"
  }
}
