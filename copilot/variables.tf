variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
  default     = "cp" 
}

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
  type        = string
  default     = "ami-062cddb9d94dcf95d"  # Amazon Linux 2023 AMI 2023.6.20250303.0 x86_64 HVM kernel-6.1
}

variable "instance_tags" {
  description = "List of tags for the EC2 instances"
  type        = list(string)
  default     = ["osj-terraform-with-cp-app-1", "osj-terraform-with-cp-app-2"]
}
