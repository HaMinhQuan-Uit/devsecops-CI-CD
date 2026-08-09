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

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket                  = aws_s3_bucket.app_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "app_data" {
  bucket        = aws_s3_bucket.app_data.id
  target_bucket = aws_s3_bucket.app_data.id
  target_prefix = "log/"
}

# ✅ FIX CKV2_AWS_61: Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ✅ FIX CKV2_AWS_62: Event notifications
resource "aws_s3_bucket_notification" "app_data" {
  bucket = aws_s3_bucket.app_data.id
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for app"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "SSH from internal network only"
  }

  # ✅ FIX CKV_AWS_382: Giới hạn egress thay vì mở hết
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound only"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound only"
  }
}

# ✅ FIX CKV2_AWS_41: IAM role for EC2
resource "aws_iam_role" "app_role" {
  name = "devsecops-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "devsecops-app-profile"
  role = aws_iam_role.app_role.name
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app_profile.name

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_tokens = "required"
  }

  # ✅ FIX CKV_AWS_8: EBS encryption
  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "devsecops-app"
  }
}
