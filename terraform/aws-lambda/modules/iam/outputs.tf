output "role_arn" {
  value = aws_iam_role.lambda.arn
}

output "policy_attachment_id" {
  value = aws_iam_role_policy_attachment.lambda_basic.id
}
