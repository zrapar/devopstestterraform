output "ec2_webserver_private_id_1" {
  value = "INSTANCE_ID_1A => ${aws_instance.webserver_1.id}"
}

output "ec2_webserver_private_id_2" {
  value = "INSTANCE_ID_2C => ${aws_instance.webserver_2.id}"
}

output "ec2_webserver_private_ip_1" {
  value = "PRIVATE_IP_1 => ${aws_instance.webserver_1.private_ip}"
}

output "ec2_webserver_private_ip_2" {
  value = "PRIVATE_IP_2 => ${aws_instance.webserver_2.private_ip}"
}

output "target_group_arn" {
  value = "TARGET_GROUP_ARN => ${aws_alb_target_group.tg.arn}"
}

output "api_gateway_endpoint" {
  value = "Invoke URL => ${aws_api_gateway_stage.api_gateway_devops_test.invoke_url}"
}

