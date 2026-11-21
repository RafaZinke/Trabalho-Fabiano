terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

variable "aws_region" {
  description = "Região liberada no AWS Academy Learner Lab"
  type        = string
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "Trabalho-Fabiano"
      Managed = "Terraform"
    }
  }
}

data "aws_availability_zones" "disponiveis" {
  state = "available"
}

resource "aws_vpc" "principal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "trabalho-fabiano-vpc"
  }
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "trabalho-fabiano-igw"
  }
}

resource "aws_subnet" "publica_a" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.disponiveis.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "trabalho-fabiano-publica-a"
  }
}

resource "aws_subnet" "publica_b" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.disponiveis.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "trabalho-fabiano-publica-b"
  }
}

resource "aws_subnet" "aplicacao" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = data.aws_availability_zones.disponiveis.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "trabalho-fabiano-aplicacao-privada"
  }
}

resource "aws_subnet" "dados" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = data.aws_availability_zones.disponiveis.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "trabalho-fabiano-dados-privada"
  }
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "trabalho-fabiano-rotas-publicas"
  }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.publica.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.principal.id
}

resource "aws_route_table_association" "publica_a" {
  subnet_id      = aws_subnet.publica_a.id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table_association" "publica_b" {
  subnet_id      = aws_subnet.publica_b.id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table" "aplicacao" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "trabalho-fabiano-rotas-aplicacao"
  }
}

resource "aws_route_table_association" "aplicacao" {
  subnet_id      = aws_subnet.aplicacao.id
  route_table_id = aws_route_table.aplicacao.id
}

resource "aws_route_table" "dados" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "trabalho-fabiano-rotas-dados"
  }
}

resource "aws_route_table_association" "dados" {
  subnet_id      = aws_subnet.dados.id
  route_table_id = aws_route_table.dados.id
}

output "vpc_id" {
  value = aws_vpc.principal.id
}

output "subredes_publicas" {
  value = [
    aws_subnet.publica_a.id,
    aws_subnet.publica_b.id
  ]
}

output "subrede_aplicacao" {
  value = aws_subnet.aplicacao.id
}

output "subrede_dados" {
  value = aws_subnet.dados.id
}
