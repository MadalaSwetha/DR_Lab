provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "dr_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "dr-vpc" }
}

# Subnet
resource "aws_subnet" "dr_subnet" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "dr-subnet" }
}

# Security Group
resource "aws_security_group" "dr_sg" {
  vpc_id = aws_vpc.dr_vpc.id
  name   = "dr-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "dr_ec2" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.dr_subnet.id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.dr_sg.id]

  tags = { Name = "dr-lab-instance" }
}

# Source S3 Bucket
resource "aws_s3_bucket" "source" {
  bucket = var.source_bucket_name
  acl    = "private"
  tags   = { Name = "dr-source-bucket" }
}

# Destination S3 Bucket
resource "aws_s3_bucket" "destination" {
  bucket = var.destination_bucket_name
  acl    = "private"
  tags   = { Name = "dr-destination-bucket" }
}

# Replication Role
resource "aws_iam_role" "replication_role" {
  name = "dr-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
      Resource = [aws_s3_bucket.source.arn]
    },
    {
      Effect   = "Allow"
      Action   = ["s3:GetObjectVersion", "s3:GetObjectVersionAcl", "s3:GetObjectVersionForReplication"]
      Resource = "${aws_s3_bucket.source.arn}/*"
    },
    {
      Effect   = "Allow"
      Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
      Resource = "${aws_s3_bucket.destination.arn}/*"
    }]
  })
}

# Replication Configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication_role.arn

  rules {
    id     = "replication-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}