variable "aws_region" {
  default     = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_1_CIDR" {
  description = "Ingress Subnet AZ 1 CIDR"
  default = "10.0.1.0/24"
}

variable "public_subnet_2_CIDR" {
  default = "10.0.2.0/24"
}

variable "private_subnet_1_CIDR" {
  default = "10.0.3.0/24"
}

variable "bastion_subnet_1_CIDR" {
  default = "10.0.7.0/24"
}

variable "private_subnet_2_CIDR" {
  default = "10.0.4.0/24"
}

variable "eks_subnet_1_CIDR" {
  default = "10.0.5.0/24"
}

variable "eks_subnet_2_CIDR" {
  default = "10.0.6.0/24"
}

variable "db_subnet_1_CIDR" {
  default = "10.0.5.0/24"
}

variable "db_subnet_2_CIDR" {
  default = "10.0.6.0/24"
}

variable "name" {
  description = "Name of the database"
  default     = "terratest-example"
}

variable "engine_name" {
  description = "Name of the database engine"
  default     = "mysql"
}

variable "family" {
  description = "Family of the database"
  default     = "mysql5.7"
}

variable "port" {
  description = "Port which the database should run on"
  default     = 3306
}

variable "major_engine_version" {
  description = "MAJOR.MINOR version of the DB engine"
  default     = "5.7"
}

variable "engine_version" {
  default     = "5.7.21"
  description = "Version of the database to be launched"
}

variable "allocated_storage" {
  default     = 5
  description = "Disk space to be allocated to the DB instance"
}

variable "license_model" {
  default     = "general-public-license"
  description = "License model of the DB instance"
}

variable "db_instance" {
  default = "db.t2.micro"
}

#### EKS Variables

variable "cluster_name" {
  default = "getting-started-eks"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    "777777777777",
    "888888888888",
  ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      rolearn  = "arn:aws:iam::66666666666:role/role1"
      username = "role1"
      groups   = ["system:masters"]
    },
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::66666666666:user/user1"
      username = "user1"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::66666666666:user/user2"
      username = "user2"
      groups   = ["system:masters"]
    },
  ]
}