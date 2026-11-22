resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.principal.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = "arn:aws:acm:us-east-1:377185077880:certificate/3a85cb6b-aa04-4fef-a95d-48cc3271e98d"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aplicacao.arn
  }
}

output "url_aplicacao" {
  value = "https://${aws_lb.principal.dns_name}"
}