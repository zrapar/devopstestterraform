# 1. Create VPC

resource "aws_vpc" "vpc_devops_test" {
  cidr_block           = "10.0.0.0/20"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_devops_test"
  }
}

## 2. Create Security Groups
resource "aws_security_group" "jumpserver_sg" {
  name = "jumpserver_sg"
  depends_on = [
    aws_vpc.vpc_devops_test
  ]
  vpc_id = aws_vpc.vpc_devops_test.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jumpserver_sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = aws_vpc.vpc_devops_test.id
  depends_on = [
    aws_vpc.vpc_devops_test
  ]

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb_sg"
  }
}

resource "aws_security_group" "webservers_sg" {
  name = "webservers_sg"
  depends_on = [
    aws_vpc.vpc_devops_test,
    aws_security_group.jumpserver_sg
  ]

  vpc_id = aws_vpc.vpc_devops_test.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumpserver_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "webservers_sg"
  }
}

# 3. Create IAM Role

resource "aws_iam_role" "ecr_role" {
  name = "ECR_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role" "ssm_role" {
  name = "SSM_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  depends_on = [
    aws_iam_role.ecr_role
  ]
  role       = aws_iam_role.ecr_role.name
  policy_arn = var.ecr_policy
}

resource "aws_iam_role_policy_attachment" "attach1" {
  depends_on = [
    aws_iam_role.ssm_role
  ]
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach2" {
  depends_on = [
    aws_iam_role.ssm_role
  ]
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "attach3" {
  depends_on = [
    aws_iam_role.ssm_role
  ]
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::961106375848:policy/ssm_policy_rest"
}

resource "aws_iam_instance_profile" "ec2_ecr_role" {
  depends_on = [
    aws_iam_role.ecr_role,
    aws_iam_role_policy_attachment.ecr_policy,
  ]
  name = "EC2_ECR_ROLE"
  role = aws_iam_role.ecr_role.name
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  depends_on = [
    aws_iam_role.ssm_role,
    aws_iam_role_policy_attachment.attach1,
    aws_iam_role_policy_attachment.attach2,
    aws_iam_role_policy_attachment.attach3,
  ]
  name = "EC2_SSM_PROFILE"
  role = aws_iam_role.ssm_role.name
}

## 4. Create Subnets

resource "aws_subnet" "vpc_devops_public_subnet_1a" {
  depends_on        = [aws_vpc.vpc_devops_test]
  vpc_id            = aws_vpc.vpc_devops_test.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "vpc_devops_public_subnet_1a"
  }
}

resource "aws_subnet" "vpc_devops_public_subnet_2c" {
  depends_on        = [aws_vpc.vpc_devops_test]
  vpc_id            = aws_vpc.vpc_devops_test.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "sa-east-1c"

  tags = {
    Name = "vpc_devops_public_subnet_2c"
  }
}

resource "aws_subnet" "vpc_devops_private_subnet_1a" {
  depends_on        = [aws_vpc.vpc_devops_test]
  vpc_id            = aws_vpc.vpc_devops_test.id
  cidr_block        = "10.0.8.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "vpc_devops_private_subnet_1a"
  }
}

resource "aws_subnet" "vpc_devops_private_subnet_2c" {
  depends_on        = [aws_vpc.vpc_devops_test]
  vpc_id            = aws_vpc.vpc_devops_test.id
  cidr_block        = "10.0.9.0/24"
  availability_zone = "sa-east-1c"

  tags = {
    Name = "vpc_devops_private_subnet_2c"
  }
}

## 5. Create Internet Gategay

resource "aws_internet_gateway" "devops_test_igw" {
  depends_on = [aws_vpc.vpc_devops_test]
  vpc_id     = aws_vpc.vpc_devops_test.id

  tags = {
    Name = "devops_test_igw"
  }
}

## 6. Create EIP

resource "aws_eip" "nat_gateway_eip_1" {
  vpc = true
}

resource "aws_eip" "nat_gateway_eip_2" {
  vpc = true
}

## 7. Create NATs

resource "aws_nat_gateway" "nat_gateway_private_1" {
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_gateway_eip_1.id
  subnet_id         = aws_subnet.vpc_devops_private_subnet_1a.id

  tags = {
    Name = "nat_gateway_private_1"
  }

  depends_on = [
    aws_eip.nat_gateway_eip_1,
    aws_eip.nat_gateway_eip_2,
    aws_internet_gateway.devops_test_igw
  ]
}

resource "aws_nat_gateway" "nat_gateway_private_2" {
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_gateway_eip_2.id
  subnet_id         = aws_subnet.vpc_devops_private_subnet_2c.id

  tags = {
    Name = "nat_gateway_private_2"
  }

  depends_on = [
    aws_eip.nat_gateway_eip_1,
    aws_eip.nat_gateway_eip_2,
    aws_internet_gateway.devops_test_igw
  ]
}

## 8. Create Route Table

resource "aws_route_table" "route_table_devops" {
  depends_on = [aws_vpc.vpc_devops_test]
  vpc_id     = aws_vpc.vpc_devops_test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_test_igw.id
  }

  tags = {
    Name = "route_table_devops_public"
  }
}

resource "aws_route_table" "route_table_devops_private_1a" {
  depends_on = [aws_vpc.vpc_devops_test, aws_nat_gateway.nat_gateway_private_1]
  vpc_id     = aws_vpc.vpc_devops_test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway_private_1.id
  }

  tags = {
    Name = "route_table_devops_private_1a"
  }
}

resource "aws_route_table" "route_table_devops_private_2c" {
  depends_on = [aws_vpc.vpc_devops_test, aws_nat_gateway.nat_gateway_private_2]
  vpc_id     = aws_vpc.vpc_devops_test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway_private_2.id
  }

  tags = {
    Name = "route_table_devops_private_2c"
  }
}

## 9. Create Route Table Associattion

resource "aws_route_table_association" "public_1a" {
  depends_on = [
    aws_route_table.route_table_devops,
    aws_subnet.vpc_devops_public_subnet_1a
  ]
  subnet_id      = aws_subnet.vpc_devops_public_subnet_1a.id
  route_table_id = aws_route_table.route_table_devops.id
}

resource "aws_route_table_association" "public_2c" {
  depends_on = [
    aws_route_table.route_table_devops,
    aws_subnet.vpc_devops_public_subnet_2c
  ]
  subnet_id      = aws_subnet.vpc_devops_public_subnet_2c.id
  route_table_id = aws_route_table.route_table_devops.id
}

resource "aws_route_table_association" "private_1a" {
  depends_on = [
    aws_route_table.route_table_devops_private_1a,
    aws_subnet.vpc_devops_private_subnet_1a
  ]
  subnet_id      = aws_subnet.vpc_devops_private_subnet_1a.id
  route_table_id = aws_route_table.route_table_devops_private_1a.id
}

resource "aws_route_table_association" "private_2c" {
  depends_on = [
    aws_route_table.route_table_devops_private_2c,
    aws_subnet.vpc_devops_private_subnet_2c
  ]
  subnet_id      = aws_subnet.vpc_devops_private_subnet_2c.id
  route_table_id = aws_route_table.route_table_devops_private_2c.id
}

## 10. Create VPC Endpoint

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc_devops_test.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  tags = {
    Name = "VPC Endpoint S3"
  }

  depends_on = [
    aws_vpc.vpc_devops_test,
    aws_route_table.route_table_devops_private_1a,
    aws_route_table.route_table_devops_private_2c
  ]
}

resource "aws_vpc_endpoint_route_table_association" "route_table_1" {
  route_table_id  = aws_route_table.route_table_devops_private_1a.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  depends_on = [
    aws_vpc_endpoint.s3,
    aws_route_table_association.private_1a,
  ]
}

resource "aws_vpc_endpoint_route_table_association" "route_table_2" {
  route_table_id  = aws_route_table.route_table_devops_private_2c.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  depends_on = [
    aws_vpc_endpoint.s3,
    aws_route_table_association.private_2c
  ]
}

## 11. Create VPC Endpoint ECR

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.vpc_devops_test.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.webservers_sg.id
  ]

  subnet_ids = [
    aws_subnet.vpc_devops_private_subnet_1a.id,
    aws_subnet.vpc_devops_private_subnet_2c.id,
  ]

  private_dns_enabled = true

  tags = {
    Name = "VPC Endpoint ECR"
  }

  depends_on = [
    aws_vpc.vpc_devops_test,
    aws_subnet.vpc_devops_private_subnet_1a,
    aws_subnet.vpc_devops_private_subnet_2c,
  ]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.vpc_devops_test.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.webservers_sg.id
  ]

  subnet_ids = [
    aws_subnet.vpc_devops_private_subnet_1a.id,
    aws_subnet.vpc_devops_private_subnet_2c.id,
  ]

  private_dns_enabled = true

  tags = {
    Name = "VPC Endpoint ECR"
  }

  depends_on = [
    aws_vpc.vpc_devops_test,
    aws_subnet.vpc_devops_private_subnet_1a,
    aws_subnet.vpc_devops_private_subnet_2c,
  ]
}

## 12. Create Target Groups

resource "aws_alb_target_group" "tg" {
  depends_on = [
    aws_vpc.vpc_devops_test,
    aws_nat_gateway.nat_gateway_private_1,
    aws_nat_gateway.nat_gateway_private_2
  ]
  name     = "tg-devops-test"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_devops_test.id
  health_check {
    path = "/"
  }
}

## 13. Create ALB
resource "aws_alb" "devops_alb" {
  depends_on = [
    aws_security_group.alb_sg,
    aws_subnet.vpc_devops_public_subnet_1a,
    aws_subnet.vpc_devops_public_subnet_2c,
    aws_nat_gateway.nat_gateway_private_1,
    aws_nat_gateway.nat_gateway_private_2,
  ]
  name               = "devops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.vpc_devops_public_subnet_1a.id, aws_subnet.vpc_devops_public_subnet_2c.id]

}

## 14. Attach Listener to ALB

resource "aws_alb_listener" "listener" {
  depends_on = [
    aws_alb.devops_alb,
    aws_alb_target_group.tg,
    aws_nat_gateway.nat_gateway_private_1,
    aws_nat_gateway.nat_gateway_private_2,
  ]
  load_balancer_arn = aws_alb.devops_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.tg.arn
    type             = "forward"
  }
}

## 15. Create Jump Server to Check

resource "aws_instance" "jumpserver" {
  depends_on = [
    aws_alb.devops_alb,
    aws_security_group.jumpserver_sg
  ]
  ami                         = "ami-037c192f0fa52a358"
  instance_type               = "t2.micro"
  user_data                   = file("files/install-ssm.sh")
  vpc_security_group_ids      = [aws_security_group.jumpserver_sg.id]
  subnet_id                   = aws_subnet.vpc_devops_public_subnet_1a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  key_name                    = "Devops"
  associate_public_ip_address = true

  tags = {
    Name = "Jumpserver"
    Project = "Devopsjump"
  }

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 8
  }
}

## 16. Create Web Server to Check

resource "aws_instance" "webserver_1" {
  depends_on = [
    aws_security_group.webservers_sg,
    aws_nat_gateway.nat_gateway_private_1,
    aws_nat_gateway.nat_gateway_private_2
  ]
  ami                    = "ami-037c192f0fa52a358"
  instance_type          = "t2.micro"
  user_data              = file("files/install-docker.sh")
  vpc_security_group_ids = [aws_security_group.webservers_sg.id]
  subnet_id              = aws_subnet.vpc_devops_private_subnet_1a.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_ecr_role.name
  key_name               = "Devops"
  availability_zone      = "sa-east-1a"

  tags = {
    Name = "WebServer 1a"
    Project = "Devopstest"
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 8
  }
}

resource "aws_instance" "webserver_2" {
  depends_on = [
    aws_security_group.webservers_sg,
    aws_nat_gateway.nat_gateway_private_1,
    aws_nat_gateway.nat_gateway_private_2
  ]
  ami                    = "ami-037c192f0fa52a358"
  instance_type          = "t2.micro"
  user_data              = file("files/install-docker.sh")
  vpc_security_group_ids = [aws_security_group.webservers_sg.id]
  subnet_id              = aws_subnet.vpc_devops_private_subnet_2c.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_ecr_role.name
  key_name               = "Devops"
  availability_zone      = "sa-east-1c"

  tags = {
    Name = "WebServer 2c"
    Project = "Devopstest"
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 8
  }
}

## 17. Register targets

resource "aws_alb_target_group_attachment" "zone_1" {
  depends_on = [
    aws_instance.webserver_1
  ]
  target_group_arn = aws_alb_target_group.tg.arn
  target_id        = aws_instance.webserver_1.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "zone_2" {
  depends_on = [
    aws_instance.webserver_2
  ]
  target_group_arn = aws_alb_target_group.tg.arn
  target_id        = aws_instance.webserver_2.id
  port             = 80
}

# 18. Create API REST

resource "aws_api_gateway_rest_api" "api_gateway_devops_test" {
  depends_on = [
    aws_alb.devops_alb,
  ]
  name = "api_gateway_devops_test"
}

resource "aws_api_gateway_integration" "root" {
  depends_on = [
    aws_api_gateway_rest_api.api_gateway_devops_test,
    aws_api_gateway_method.root,
    aws_alb.devops_alb
  ]
  rest_api_id             = aws_api_gateway_rest_api.api_gateway_devops_test.id
  resource_id             = aws_api_gateway_rest_api.api_gateway_devops_test.root_resource_id
  http_method             = aws_api_gateway_method.root.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = aws_api_gateway_method.root.http_method
  uri                     = "http://${aws_alb.devops_alb.dns_name}"
}

resource "aws_api_gateway_method" "root" {
  depends_on = [
    aws_api_gateway_rest_api.api_gateway_devops_test,
  ]
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_rest_api.api_gateway_devops_test.root_resource_id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway_devops_test.id
}

resource "aws_api_gateway_resource" "proxy" {
  depends_on = [
    aws_api_gateway_rest_api.api_gateway_devops_test
  ]
  rest_api_id = aws_api_gateway_rest_api.api_gateway_devops_test.id
  parent_id   = aws_api_gateway_rest_api.api_gateway_devops_test.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway_devops_test.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = aws_api_gateway_method.proxy.http_method
  uri                     = "http://${aws_alb.devops_alb.dns_name}/{proxy}"
  cache_key_parameters    = ["method.request.path.proxy"]
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  depends_on = [
    aws_alb.devops_alb,
    aws_api_gateway_rest_api.api_gateway_devops_test,
    aws_api_gateway_method.proxy,
  ]
}

resource "aws_api_gateway_method" "proxy" {
  depends_on = [
    aws_api_gateway_rest_api.api_gateway_devops_test,
    aws_api_gateway_resource.proxy
  ]
  rest_api_id   = aws_api_gateway_rest_api.api_gateway_devops_test.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_deployment" "api_gateway_devops_test" {
  depends_on = [
    aws_api_gateway_rest_api.api_gateway_devops_test,
    aws_api_gateway_resource.proxy,
    aws_api_gateway_method.root,
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.root,
    aws_api_gateway_integration.proxy
  ]
  rest_api_id = aws_api_gateway_rest_api.api_gateway_devops_test.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_rest_api.api_gateway_devops_test.root_resource_id,
      aws_api_gateway_method.root.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.root.id,
      aws_api_gateway_integration.proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_gateway_devops_test" {
  depends_on = [
    aws_api_gateway_deployment.api_gateway_devops_test,
    aws_api_gateway_rest_api.api_gateway_devops_test
  ]
  deployment_id = aws_api_gateway_deployment.api_gateway_devops_test.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway_devops_test.id
  stage_name    = "dev"
}

# 21. Copy File to Bastion Host

resource "null_resource" "copy_files" {
  depends_on = [
    aws_instance.jumpserver
  ]
  provisioner "local-exec" {
    command = "sed -i -e 's#__USER_HOST__#${var.user_host}#g' files/upload-file.sh && sed -i -e 's#__JUMPSERVER_IP__#${aws_instance.jumpserver.public_ip}#g' files/upload-file.sh && cat files/upload-file.sh && chmod +x files/upload-file.sh && ./files/upload-file.sh"
  }
}

