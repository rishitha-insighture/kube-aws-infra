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

# If this changes. Subnets should also reflect this.
#  eg:- VPC: 10.1.0.0/16
#       pub_subnet: 10.1.1.0/24
#       priv_subnet: 10.1.2.0/24
#
#  Because when we transitioning one environment to another
#   IP conflicts should not be happen.
# 
variable "vpc_cidr_range" {
  description = "VPC cidr range. This differ from environment to environment"
  default     = "10.1.0.0/16"
}

variable "vpc_public_subnet" {
  description = "Public subnet"
  default     = "10.1.1.0/24"
}

variable "vpc_private_subnet" {
  description = "Private subnet"
  default     = "10.1.2.0/24"
}

variable "common_tags" {
  description = "A set of common tags to apply to all resources"
  type        = map(string)
  default = {
    owner = "pathum.kerner14"
    test = "yes"
  }
}

variable "instance_count" {
  default = 5
}

variable "node_ami_id" {
  description = "AMI Id used for nodes"
  default     = "ami-0f9bb76db27240e62"
  # default     = "ami-04588d67f856d6aad" # us-east-1
}

variable "bastion_ami_id" {
  description = "AMI Id used for nodes"
  default     = "ami-02a065c808acdbda1"
  # default = "ami-00e5812396dc365ac" # us-east-1
}
