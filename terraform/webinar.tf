# Configure aws provider, give it access and point it towards the correct region
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

# Add SSH key 
resource "aws_key_pair" "aws_key" {
  key_name    = "aws_key"
  public_key  = file(var.aws_key)
}

# Allow SSH connections from Puppet
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow ssh and HTTP over ports 22 and 80"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance for load balancer
resource "aws_instance" "load_balancer" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = "aws_key"
  security_groups = ["allow_ssh_http"]
  count = 1
  depends_on = [
    aws_key_pair.aws_key,
    aws_security_group.allow_ssh_http
  ]
}

# Create EC2 instance for web servers
resource "aws_instance" "web_servers" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = "aws_key"
  security_groups = ["allow_ssh_http"]
  count = 2
  depends_on = [
    aws_key_pair.aws_key,
    aws_security_group.allow_ssh_http
  ]
}
