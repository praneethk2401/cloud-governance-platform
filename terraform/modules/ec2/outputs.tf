output "instance_ids" {
  description = "IDs of the EC2 instances created"
  value       = aws_instance.servers[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.servers[*].private_ip
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2_sg.id
}

output "ssm_role_arn" {
  description = "ARN of the SSM IAM role"
  value       = aws_iam_role.ssm_role.arn
}