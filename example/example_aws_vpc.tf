# Provision a VPC to start
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Owner = "Ranjit"
  }
}

# Capture the ARN for importing later
output "ARN" {
  value = aws_vpc.main.arn
}
