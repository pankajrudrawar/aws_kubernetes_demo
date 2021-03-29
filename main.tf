provider "aws" {
  region = var.aws_region
  access_key = "AKIA4RBXIIWMWKC6G67M"
  secret_key = "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"
  max_retries = 1

   public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

### EKS Variables
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
}

### EKS Variables

data "aws_subnet_ids" "all" {
  vpc_id = aws_vpc.test_vpc.id
}

locals {
  name   = "complete-postgresql"
  region = "us-east-1"
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

resource "aws_vpc" "test_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    name  = "First-VPC"
  }
}

resource "aws_internet_gateway" "test_gw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    name  = "First-IG"
  }
}


# Public Subnet - 1A
resource "aws_subnet" "public_subnet-1a" {
  cidr_block = var.public_subnet_1_CIDR
  vpc_id = aws_vpc.test_vpc.id
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name  = "Test-Public-Subnet-1A"
  }

}

# Public Subnet - 1B

resource "aws_subnet" "public_subnet-1b" {
  cidr_block = var.public_subnet_2_CIDR
  vpc_id = aws_vpc.test_vpc.id
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

  tags = {
    Name  = "Test-Public-Subnet-1b"
  }
}

# Bastion Public Subnet 1A

resource "aws_subnet" "bastion_subnet-1a" {
  cidr_block = var.bastion_subnet_1_CIDR
  vpc_id = aws_vpc.test_vpc.id
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name  = "Bastion-Public-Subnet-1A"
  }

}

# Private Subnet - 1A
resource "aws_subnet" "private_subnet-1a" {
  cidr_block = var.private_subnet_1_CIDR
  vpc_id = aws_vpc.test_vpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name  = "Test-Private-Subnet-1A"
  }
}

# Private Subnet - 1B

resource "aws_subnet" "private_subnet-1b" {
  cidr_block = var.private_subnet_2_CIDR
  vpc_id = aws_vpc.test_vpc.id
  availability_zone = "us-east-1b"

  tags = {
    Name  = "Test-Private-Subnet-1b"
  }
}

# EKS Subnet - 1A

resource "aws_subnet" "eks_subnet-1a" {
  cidr_block = var.eks_subnet_1_CIDR
  vpc_id = aws_vpc.test_vpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name  = "Test-EKS-Subnet-1a"
  }
}

# EKS Subnet - 1B

resource "aws_subnet" "eks_subnet-1b" {
  cidr_block = var.eks_subnet_2_CIDR
  vpc_id = aws_vpc.test_vpc.id
  availability_zone = "us-east-1b"

  tags = {
    Name  = "Test-EKS-Subnet-1b"
  }
}



# DB Subnet

resource "aws_db_subnet_group" "test_rds_sub_group" {
  name = "rds-db-subnet-group"
  subnet_ids = [var.db_subnet_1_CIDR,var.db_subnet_2_CIDR]
}


# Nat Gateway

resource "aws_eip" "test_nat_eip1" {
  vpc = true
  depends_on = [aws_internet_gateway.test_gw]
}

resource "aws_eip" "test_nat_eip2" {
  vpc = true
  depends_on = [aws_internet_gateway.test_gw]
}

resource "aws_nat_gateway" "test-nat-gw1" {
  allocation_id = aws_eip.test_nat_eip1.id
  subnet_id = aws_subnet.public_subnet-1a.id

  tags = {
    Name  = "First Nat Gateway"
  }
}

resource "aws_nat_gateway" "test-nat-gw2" {
  allocation_id = aws_eip.test_nat_eip2.id
  subnet_id = aws_subnet.public_subnet-1b.id

  tags = {
    Name  = "Second Nat Gateway"
  }
}


#Public Route Table

resource "aws_route_table" "test_public_route" {
  vpc_id = aws_vpc.test_vpc.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_gw.id
  }

  tags = {
    name  = "First-Public-Route"
  }
}

# NAT Route Table for

resource "aws_route_table" "test_app_route1" {
  vpc_id = aws_vpc.test_vpc.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.test-nat-gw1.id
  }

  tags = {
    name  = "First-NAT-Route"
  }
}

resource "aws_route_table" "test_app_route2" {
  vpc_id = aws_vpc.test_vpc.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.test-nat-gw2.id
  }

  tags = {
    name  = "Second-NAT-Route"
  }
}

#Subnet Associate

resource "aws_route_table_association" "test-subnet-assoc-1a" {
  subnet_id = aws_subnet.public_subnet-1a.id
  route_table_id = aws_route_table.test_public_route.id
}

resource "aws_route_table_association" "test-subnet-assoc-1b" {
  subnet_id = aws_subnet.public_subnet-1b.id
  route_table_id = aws_route_table.test_public_route.id
}

#App Route Table Association

resource "aws_route_table_association" "app-subnet-assoc-1a" {
  subnet_id = aws_subnet.private_subnet-1a.id
  route_table_id = aws_route_table.test_app_route1.id
}

resource "aws_route_table_association" "app-subnet-assoc-1b" {
  subnet_id = aws_subnet.private_subnet-1b.id
  route_table_id = aws_route_table.test_app_route2.id
}


# Security Group

resource "aws_security_group" "test-alb-sg" {
  name   = "test-alb-sg"
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      var.private_subnet_1_CIDR]
  }

  egress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      var.private_subnet_2_CIDR]
  }

}

resource "aws_security_group" "test-app-sg" {
  name   = "test-app-sg"
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [var.public_subnet_1_CIDR]
  }

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [var.public_subnet_2_CIDR]
  }

  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = [var.public_subnet_1_CIDR]
  }

  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = [var.public_subnet_2_CIDR]
  }

  ingress {
    from_port = 3389
    protocol = "tcp"
    to_port = 3389
    cidr_blocks = [var.bastion_subnet_1_CIDR]
  }
  egress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
  }
  egress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }
  egress {
    from_port = 3389
    protocol = "tcp"
    to_port = 3389
  }

}

resource "aws_security_group" "db_instance" {
  name = "rds-sg"
  vpc_id = aws_vpc.test_vpc.id
}

resource "aws_security_group_rule" "my-rds-sg-rule" {
  from_port         = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.db_instance.id
  to_port           = 1433
  type              = "ingress"
  cidr_blocks       = [var.private_subnet_1_CIDR,var.private_subnet_2_CIDR,var.bastion_subnet_1_CIDR]
}

resource "aws_security_group_rule" "my-rds-sg-rule1" {
  from_port         = 3389
  protocol          = "tcp"
  security_group_id = aws_security_group.db_instance.id
  to_port           = 3389
  type              = "ingress"
  cidr_blocks       = [var.bastion_subnet_1_CIDR]
}

resource "aws_security_group_rule" "outbound_rule" {
  from_port         = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.db_instance.id
  to_port           = 1433
  type              = "egress"
  cidr_blocks       = [var.private_subnet_1_CIDR,var.private_subnet_2_CIDR,var.bastion_subnet_1_CIDR]
}

resource "aws_security_group_rule" "outbound_rule1" {
  from_port         = 3389
  protocol          = "tcp"
  security_group_id = aws_security_group.db_instance.id
  to_port           = 3389
  type              = "egress"
  cidr_blocks       = [var.bastion_subnet_1_CIDR]
}

resource "aws_security_group" "test-bastion-sg" {
  name   = "test-bastion-sg"
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = -1
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }

}

### EKS Security Group

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

### EKS Security Group


##### EC2 Bastion Instance Creation #####

resource "aws_launch_configuration" "terra_bastion_lc" {
#  name_prefix   = "terraform-bastion-"
  image_id      = "ami-01e24be29428c15b2"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.test_key.key_name
  security_groups = [aws_security_group.test-bastion-sg.id]

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "terra-bastion" {
  name                 = "terraform-bastion-asg"
  launch_configuration = aws_launch_configuration.terra_bastion_lc.name
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet-1a.id]

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_key_pair" "test_key" {
  key_name = "key_name"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH7Phjjy36boN0LOKl5Fnmw8VDM16VX1i2qYqKT4a2syGwHmqIosbf5cU2rHi8VSGmWOBohbDKuw+yI6ldJilaAGz0D4JUv3dNMsGg7A0JMxe9nL6Y4t5HnLTxTn8eF9ttAP3PDrTh+IYOQjZ1w2FUKsPVGNg3tgrnpVXZ2Gttc5bXiJVVeTxSxVIT7numi6EnSbr1oQY9npmW5GQBSZcoFYqOgyJdPdeyWsm3dNM+eDmuy6H+EI52wFJSiQPKD+PkSa0S1TPK4Sfmlyj2QyBB/aWnBEpvJytv9TTk0SIDVuqlbUZwEv60U1rG9RGDPpXWhIlYekz5mXF9EooYsYcT pankaj@DESKTOP-AB5856C"
}

##### EC2 Web App Instance Creation #####

data "aws_ami" "nginx-ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["nginx-plus-ami-ubuntu-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"] # Canonical
}

resource "aws_launch_configuration" "test_web_server" {
  name_prefix   = "test_web_server-"
  image_id      = data.aws_ami.nginx-ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.test_key.key_name
  security_groups = [
    aws_security_group.test-app-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "test-app-asg_1" {
  name                 = "test_auto-1"
  launch_configuration = aws_launch_configuration.test_web_server.name
  min_size             = 1
  max_size             = 2
  vpc_zone_identifier       = [aws_subnet.private_subnet-1a.id]
  target_group_arns         = [aws_lb_target_group.test-lb-group.id]

  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_autoscaling_group" "test-app-asg_2" {
  name                 = "test_auto-2"
  launch_configuration = aws_launch_configuration.test_web_server.name
  min_size             = 1
  max_size             = 2
  vpc_zone_identifier       = [aws_subnet.private_subnet-1b.id]
  target_group_arns         = [aws_lb_target_group.test-lb-group.id]

  lifecycle {
    create_before_destroy = true
  }

}

# DB Creation

resource "aws_db_instance" "my-test-sql" {
  instance_class          = var.db_instance
  engine                  = "mysql"
  engine_version          = "5.7"
  multi_az                = true
  storage_type            = "gp2"
  allocated_storage       = 20
  name                    = "mytestrds"
  username                = "admin"
  password                = "admin123"
  apply_immediately       = "true"
  backup_retention_period = 7
  backup_window           = "09:46-10:16"
  db_subnet_group_name    = aws_db_subnet_group.test_rds_sub_group.name
  vpc_security_group_ids  = [aws_security_group.db_instance.id]
}



# Load Balancer Creation

resource "aws_lb" "test-lb" {
  name = "test-alb"
  internal = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  enable_deletion_protection = false

  security_groups = [
  aws_security_group.test-alb-sg.id
  ]

  subnets = [
    aws_subnet.public_subnet-1a.id,
    aws_subnet.public_subnet-1b.id

  ]

  tags = {
    Name = "my-test-alb"
  }

}

resource "aws_lb_target_group" "test-lb-group" {
  health_check {
    interval  = 10
    path      = "/"
    protocol  = "https"
    timeout   = "5"
    healthy_threshold = 5
    unhealthy_threshold = 2
  }

  name = "test-tg"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = aws_vpc.test_vpc.id
}

resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.test-app-asg_1.id
  alb_target_group_arn = aws_lb_target_group.test-lb-group.arn
}

resource "aws_lb_listener" "my-test-alb-listner" {
  load_balancer_arn = aws_lb.test-lb.arn
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-lb-group.id
  }

}

### WAF ACL RUles ####

module "waf" {
  source = "../.."

  name_prefix = "test-waf-setup"
  alb_arn     = aws_lb.test-lb.arn

  allow_default_action = true

  create_alb_association = true

  visibility_config = {
    cloudwatch_metrics_enabled = false
    metric_name                = "test-waf-setup-waf-main-metrics"
    sampled_requests_enabled   = false
  }

  rules = [
    {
      name     = "AWSManagedRulesCommonRuleSet-rule-1"
      priority = "1"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesCommonRuleSet-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        excluded_rule = [
          "SizeRestrictions_QUERYSTRING",
          "SizeRestrictions_BODY",
          "GenericRFI_QUERYARGUMENTS"
        ]
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet-rule-2"
      priority = "2"

      override_action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesKnownBadInputsRuleSet-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesPHPRuleSet-rule-3"
      priority = "3"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesPHPRuleSet-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"
      }
    }
  ]

  tags = {
    "Environment" = "test"
  }
}

### WAF ACL RUles ####

resource "aws_security_group_rule" "inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.test-alb-sg.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.test-alb-sg.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.test-alb-sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


#### EKS Setup ####

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.17"
  subnets         = [aws_subnet.eks_subnet-1a,aws_subnet.eks_subnet-1b]
  version = "12.2.0"
  cluster_create_timeout = "1h"
  cluster_endpoint_private_access = true

  vpc_id = aws_vpc.test_vpc.id

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
  ]

  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  map_roles                            = var.map_roles
  map_users                            = var.map_users
  map_accounts                         = var.map_accounts
}



provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
#  version                = "~> 1.11"
}

resource "kubernetes_deployment" "example" {
  metadata {
    name = "terraform-example"
    labels = {
      test = "MyExampleApp"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        test = "MyExampleApp"
      }
    }

    template {
      metadata {
        labels = {
          test = "MyExampleApp"
        }
      }

      spec {
        container {
          image = "nginx:1.7.8"
          name  = "example"

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "example" {
  metadata {
    name = "terraform-example"
  }
  spec {
    selector = {
      test = "MyExampleApp"
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
