resource "aws_wafv2_web_acl" "principal" {
  name        = "trabalho-fabiano-waf"
  description = "Protecao da aplicacao"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "regras-comuns-aws"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "fabiano-regras-comuns"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "limite-por-ip"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = 2000
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "fabiano-limite-ip"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "trabalho-fabiano-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "trabalho-fabiano-waf"
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.principal.arn
  web_acl_arn  = aws_wafv2_web_acl.principal.arn
}