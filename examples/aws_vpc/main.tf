provider "aws" {
  region     = local.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  region                   = "ap-northeast-1"                                // only supports "ap-northeast-1" for now
  jump_instance_username   = "ec2-user"                                      // depends on AMI
  ssh_private_key_filepath = trimsuffix(var.ssh_public_key_filepath, ".pub") // guess it from public key filepath
  tags = {
    Name = "lerna-example"
  }
  owner_id               = module.vpc.vpc_owner_id
  vpc_id                 = module.vpc.vpc_id
  igw_id                 = module.vpc.igw_id
  natgw_id               = module.vpc.natgw_ids[0]
  private_subnet_id      = module.vpc.private_subnets[0]
  public_subnet_id       = module.vpc.public_subnets[0]
  private_route_table_id = module.vpc.private_route_table_ids[0]
  public_route_table_id  = module.vpc.public_route_table_ids[0]
  security_group_id      = module.vpc.default_security_group_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"
  tags    = local.tags

  name = "lerna-example"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a"]
  public_subnets  = ["10.0.101.0/24"]
  private_subnets = ["10.0.1.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "security" {
  source = "./modules/security"
  tags   = local.tags

  keepalived_route_table_id       = local.private_route_table_id
  keepalived_route_table_owner_id = local.owner_id
}

module "jump_instance" {
  source = "./modules/jump_instance"
  tags   = local.tags

  # Amazon Linux 2 AMI 2.0.20201126.0 x86_64 HVM gp2
  ami            = "ami-00f045aed21a55240"
  instance_type  = "t2.micro"
  subnet_id      = local.private_subnet_id
  ssh_public_key = file(var.ssh_public_key_filepath)
}
