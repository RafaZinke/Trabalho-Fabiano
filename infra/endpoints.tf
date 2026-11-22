resource "aws_security_group" "endpoints" {
  name        = "trabalho-fabiano-endpoints"
  description = "Acesso privado ao Systems Manager"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "trabalho-fabiano-endpoints"
  }
}

locals {
  grupos_ec2 = {
    aplicacao = aws_security_group.aplicacao.id
    banco     = aws_security_group.banco.id
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_das_ec2" {
  for_each = local.grupos_ec2

  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = each.value
  description                  = "HTTPS da EC2 ${each.key}"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "ec2_para_endpoints" {
  for_each = local.grupos_ec2

  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.endpoints.id
  description                  = "HTTPS para endpoints privados"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_endpoint" "systems_manager" {
  for_each = toset(["ssm", "ssmmessages"])

  vpc_id              = aws_vpc.principal.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [aws_subnet.aplicacao.id]
  security_group_ids = [aws_security_group.endpoints.id]

  tags = {
    Name = "trabalho-fabiano-${each.value}"
  }
}