data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "aplicacao" {
  ami           = nonsensitive(data.aws_ssm_parameter.amazon_linux.value)
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.aplicacao.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.aplicacao.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable --now amazon-ssm-agent
  EOF

  tags = {
    Name = "trabalho-fabiano-aplicacao"
  }
}

resource "aws_instance" "banco" {
  ami           = nonsensitive(data.aws_ssm_parameter.amazon_linux.value)
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.dados.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.banco.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable --now amazon-ssm-agent
  EOF

  tags = {
    Name = "trabalho-fabiano-banco"
  }
}

output "ec2_aplicacao_id" {
  value = aws_instance.aplicacao.id
}

output "ec2_banco_id" {
  value = aws_instance.banco.id
}

output "ip_privado_aplicacao" {
  value = aws_instance.aplicacao.private_ip
}

output "ip_privado_banco" {
  value = aws_instance.banco.private_ip
}