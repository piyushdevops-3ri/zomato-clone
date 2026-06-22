variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI for ap-south-1"
  type        = string
  default     = "ami-0f5ee92e2d63afc18"   # Ubuntu 22.04 LTS ap-south-1 (Mumbai)
}

variable "instance_type" {
  description = "EC2 instance type - t2.large recommended for Jenkins+SonarQube"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "zomato-jenkins-key"
}

variable "allowed_ports" {
  description = "Ports to open in the security group"
  type        = list(number)
  default     = [
    22,    # SSH
    80,    # HTTP
    443,   # HTTPS
    8080,  # Jenkins
    9000,  # SonarQube
    3000   # Zomato App
  ]
}
