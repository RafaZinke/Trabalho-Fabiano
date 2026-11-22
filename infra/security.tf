resource "aws_security_group" "alb" {
  name        = "trabalho-fabiano-alb"
  description = "Acesso ao balanceador"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "trabalho-fabiano-alb"
  }
}

resource "aws_security_group" "aplicacao" {
  name        = "trabalho-fabiano-aplicacao"
  description = "Acesso a aplicacao"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "trabalho-fabiano-aplicacao"
  }
}

resource "aws_security_group" "banco" {
  name        = "trabalho-fabiano-banco"
  description = "Acesso ao PostgreSQL"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "trabalho-fabiano-banco"
  }
}

resource "aws_vpc_security_group_ingress_rule" "https_alb" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS da internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_para_aplicacao" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.aplicacao.id
  description                  = "ALB para aplicacao"
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
}

resource "aws_vpc_security_group_ingress_rule" "aplicacao_do_alb" {
  security_group_id            = aws_security_group.aplicacao.id
  referenced_security_group_id = aws_security_group.alb.id
  description                  = "Aplicacao recebe somente do ALB"
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
}

resource "aws_vpc_security_group_egress_rule" "aplicacao_para_banco" {
  security_group_id            = aws_security_group.aplicacao.id
  referenced_security_group_id = aws_security_group.banco.id
  description                  = "Aplicacao para PostgreSQL"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "banco_da_aplicacao" {
  security_group_id            = aws_security_group.banco.id
  referenced_security_group_id = aws_security_group.aplicacao.id
  description                  = "PostgreSQL recebe somente da aplicacao"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}