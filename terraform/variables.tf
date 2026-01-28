variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "source_bucket_name" {
  description = "Source S3 bucket name"
  type        = string
}

variable "destination_bucket_name" {
  description = "Destination S3 bucket name"
  type        = string
}