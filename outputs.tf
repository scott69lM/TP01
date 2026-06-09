output "bucket_name" {
  value = aws_s3_bucket.main.id
}

output "bucket_arn" {
  value = aws_s3_bucket.main.arn
}

output "bucket_region" {
  value = aws_s3_bucket.main.region
}

output "versioning_status" {
  value = aws_s3_bucket_versioning.main.versioning_configuration[0].status
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}