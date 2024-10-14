variable "aws_region" {
  description = "The AWS region to deploy resources in"
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "The AWS profile to use from ~/.aws/credentials"
  default     = "tf_user"
}

variable "ssh_key_path" {
  description = "Path to the local SSH public key"
  default     = "~/.ssh/aws-temp.pub"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair"
  default     = "bastion_key_pair"
}

variable "common_tags" {
  description = "A set of common tags to apply to all resources"
  type        = map(string)
  default = {
    owner = "pathum.kalhan"
    test = "yes"
  }
}

variable "instance_count" {
  default = 3
}
