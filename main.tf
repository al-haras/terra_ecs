provider "aws" {
  region = var.region
}

module "efs" {
  source     = "git::https://github.com/cloudposse/terraform-aws-efs.git?ref=master"

  name               = "minecraft"
  region             = var.region
  vpc_id             = module.vpc_setup.vpc_id
  subnets            = module.vpc_setup.public_subnets
  availability_zones = module.vpc_setup.azs
  security_groups    = [module.efs_sg.this_security_group_id]
}

module "vpc_setup" {
  source = "terraform-aws-modules/vpc/aws"

  name = "minecraft"
  cidr = "10.0.0.0/16"
  azs             = ["us-west-1b", "us-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.103.0/24"]
  
  public_subnet_tags = {
    Name = "minecraft-public"
  }

  private_subnet_tags = {
    Name = "minecraft-private"
  }

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = false
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Terraform = "true"
    Name      = "minecraft"
  }

}

# Creation of Security Group to allow traffic on 25565 (Minecraft) and 22 (SSH, configured to your known public IP address).
module "main_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.0.1"

  name                = "minecraft"
  description         = "Set Traffic to allow 25565 (everywhere) and SSH from single public IP address"
  vpc_id              = module.vpc_setup.vpc_id
  egress_rules        = ["all-all"]
  ingress_rules       = ["ssh-tcp"]
  ingress_cidr_blocks = [join("", [chomp(data.http.icanhazip.body), "/32"])]
  ingress_with_cidr_blocks = [
    {
      from_port   = 25565
      to_port     = 25565
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

# Creation of Security group to allow NFS Permissions (EFS)
module "efs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.0.1"

  name                = "efs_sg"
  description         = "Allow Port 2049"
  vpc_id              = module.vpc_setup.vpc_id
  egress_rules        = ["all-all"]
  ingress_rules       = ["nfs-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ecs_create" {
  source = "terraform-aws-modules/ecs/aws"
  name = "mine-cluster"
}

resource "aws_instance" "default" {
  ami             = data.aws_ami.latest_ecs.image_id
  instance_type   = "t2.medium"
  depends_on      = [module.efs.id]
  security_groups = [module.main_sg.this_security_group_id, module.efs_sg.this_security_group_id]
  user_data       = data.template_file.ecs_mount.rendered
  key_name        = aws_key_pair.default.key_name
  subnet_id       = module.vpc_setup.public_subnets[0]
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "default" {
  key_name   = "server"
  public_key = tls_private_key.default.public_key_openssh
}

resource "local_file" "ssh_private_key" {
  content  = tls_private_key.default.private_key_pem
  filename = "server.pem"
}

resource "null_resource" "chmod" {
  depends_on = [local_file.ssh_private_key]

  provisioner "local-exec" {
    command = format("chmod 600 %s", local_file.ssh_private_key.filename)
  }
}

data "http" "icanhazip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_ami" "latest_ecs" {
most_recent = true
owners = ["591542846629"]

  filter {
      name   = "name"
      values = ["*amazon-ecs-optimized"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }  
}

data "template_file" "ecs_mount" {
  template = "${file("./bootstrap.sh.tpl")}"
  vars = {
    efs_id = "${module.efs.id}"
    cluster_name = "${module.ecs_create.this_ecs_cluster_name}"
  }
}