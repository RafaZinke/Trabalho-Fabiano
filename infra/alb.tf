resource "aws_lb" "principal" {
  name               = "trabalho-fabiano-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.publica_a.id,
    aws_subnet.publica_b.id
  ]

  tags = {
    Name = "trabalho-fabiano-alb"
  }
}

resource "aws_lb_target_group" "aplicacao" {
  name        = "trabalho-fabiano-app"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.principal.id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "aplicacao" {
  target_group_arn = aws_lb_target_group.aplicacao.arn
  target_id        = aws_instance.aplicacao.id
  port             = 8000
}

output "alb_dns" {
  value = aws_lb.principal.dns_name
}