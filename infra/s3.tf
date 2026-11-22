resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.principal.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.aplicacao.id,
    aws_route_table.dados.id
  ]

  tags = {
    Name = "trabalho-fabiano-s3"
  }
}

resource "aws_vpc_security_group_egress_rule" "ec2_para_s3" {
  for_each = local.grupos_ec2

  security_group_id = each.value
  description       = "HTTPS para Amazon S3"
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}