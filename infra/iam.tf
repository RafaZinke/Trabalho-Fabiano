data "aws_iam_instance_profile" "lab" {
  name = "LabInstanceProfile"
}

output "perfil_ec2" {
  value = data.aws_iam_instance_profile.lab.name
}