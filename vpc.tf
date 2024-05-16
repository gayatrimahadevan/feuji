module "label_vpc" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "vpc"
  attributes = ["main"]
}
module "label_public_subnet" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "subnet"
  attributes = ["public"]
}
module "label_private_subnet" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "subnet"
  attributes = ["private"]
}
module "label_internet_gateway" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  context = module.base_label.context
  name    = "ig"
}
module "label_rt_public" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "rt"
  attributes = ["public"]
}
module "label_rt_private" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "rt"
  attributes = ["private"]
}
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = module.label_vpc.tags
}

# =========================
# Create your subnets here
# =========================
module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vpc_cidr
  networks = [
    {
      name     = module.label_public_subnet.id
      new_bits = 24 - tonumber(split("/", var.vpc_cidr)[1])
    },
    {
      name     = module.label_private_subnet.id
      new_bits = 24 - tonumber(split("/", var.vpc_cidr)[1])
    }
  ]
}
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = module.subnet_addrs.networks[0].cidr_block
  map_public_ip_on_launch = "true"
  tags              = module.label_public_subnet.tags
}
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = module.subnet_addrs.networks[1].cidr_block
  tags              = module.label_private_subnet.tags
}
# Internet GW
resource "aws_internet_gateway" "ll-ig" {
  vpc_id = aws_vpc.main.id
  tags   = module.label_internet_gateway.tags
}
# route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ll-ig.id
  }
  tags = module.label_rt_public.tags
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = module.label_rt_private.tags
}
# route associations public
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
# route associations private
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
