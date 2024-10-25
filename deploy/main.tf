# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14.0"
  name    = "${var.cluster_name}-vpc"

  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  private_subnet_names = [
    "${var.cluster_name}-private-${var.aws_region}a",
    "${var.cluster_name}-private-${var.aws_region}b",
    "${var.cluster_name}-private-${var.aws_region}c"
  ]

  public_subnet_names = [
    "${var.cluster_name}-public-${var.aws_region}a",
    "${var.cluster_name}-public-${var.aws_region}b",
    "${var.cluster_name}-public-${var.aws_region}c"
  ]

  tags = {
    Environment = "dev"
  }
}

# EKS Module
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.14.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  create_iam_role = true
  # Disable the creation of CloudWatch log group in the module
  create_cloudwatch_log_group = false

  eks_managed_node_groups = {
    default = {
      desired_size = 1
      max_size     = 2
      min_size     = 1

      # Modify instance types to use fewer instance types to reduce fleet requests
      instance_types = ["t3.small"] # Remove t3.medium to reduce fleet requests
      capacity_type  = "ON_DEMAND"  # Change to ON_DEMAND to avoid SPOT fleet requests

      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        Environment = "dev"
        GithubRepo  = "terraform-aws-eks"
      }

      tags = {
        Name = "${var.cluster_name}-worker"
      }
    }
  }

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      name                       = "${var.cluster_name}-egress-ephemeral"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  cluster_security_group_name = "${var.cluster_name}-cluster-sg"
  node_security_group_name    = "${var.cluster_name}-node-sg"

  tags = {
    Name        = var.cluster_name
    Environment = "dev"
  }
}

# Data Sources
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# ECR Repository
resource "aws_ecr_repository" "dotnet_cache_load_test_web_api" {
  name                 = "dotnet-cache-load-test-web-api"
  image_tag_mutability = "MUTABLE"
  tags = {
    Name        = "dotnet-cache-load-test-web-api"
    Environment = "dev"
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}

# IAM Role Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = module.eks.cluster_iam_role_name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = module.eks.cluster_iam_role_name
}

# IAM Role Policies
resource "aws_iam_role_policy" "eks_additional_policy" {
  name = "${var.cluster_name}-additional-policy"
  role = module.eks.cluster_iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "deny_cloudwatch_creation" {
  name = "${var.cluster_name}-deny-cloudwatch-creation"
  role = module.eks.cluster_iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = ["logs:CreateLogGroup"]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name        = "/aws/eks/${var.cluster_name}/cluster"
    Environment = "dev"
  }

  # Add lifecycle rule to prevent recreation
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name
    ]
  }
}
