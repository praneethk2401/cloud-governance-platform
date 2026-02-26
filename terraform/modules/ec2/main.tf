# IAM Role so SSM can manage these instances
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-${var.environment}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ssm-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach SSM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile - attaches IAM role to EC2
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-${var.environment}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# Security Group - controls traffic to EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for ${var.environment} EC2 instances"
  vpc_id      = var.vpc_id

  # No inbound SSH - we use SSM instead
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2 Instances
resource "aws_instance" "servers" {
  count                  = var.instance_count
  ami                    = "ami-093d18e415752df8d"
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-server-${count.index + 1}"
    Environment = var.environment
    Patch_Group = var.environment
    Project     = var.project_name
  }
}