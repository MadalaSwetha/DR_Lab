output "ec2_public_ip" {
  value = aws_instance.dr_ec2.public_ip
}

output "source_bucket_arn" {
  value = aws_s3_bucket.source.arn
}

output "destination_bucket_arn" {
  value = aws_s3_bucket.destination.arn
}