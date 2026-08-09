provider "aws" {
  region = "ap-southeast-1"
}

# ⚠️ LỖI CỐ Ý: S3 bucket thiếu encryption, thiếu versioning,
# thiếu public access block → Checkov sẽ phát hiện
resource "aws_s3_bucket" "app_data" {
  bucket = "devsecops-demo-data"

  tags = {
    Environment = "staging"
    Project     = "devsecops-pipeline"
  }
}

# ⚠️ LỖI CỐ Ý: Security Group mở SSH cho toàn internet
# Thực tế chỉ nên cho IP cụ thể (VPN, office)
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for app"

  # Port 22 mở cho 0.0.0.0/0 → ai cũng SSH được
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cho phép tất cả traffic ra ngoài
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # ⚠️ Thiếu monitoring = true → Checkov flag
  # ⚠️ Thiếu metadata_options (IMDSv2) → Checkov flag

  tags = {
    Name = "devsecops-app"
  }
}
