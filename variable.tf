variable "aws_region" {
    type = string
    default = "sa-east-1"
}

variable "aws_access_key" {
    type = string
}

variable "aws_secret_key" {
    type = string
}

variable "port" {
    type = number
    default = 6500
}

variable "image_id" {
    type = string
}

variable "ecr_policy" {
    type = string
    default = "arn:aws:iam::961106375848:policy/ECRPowerUser"
}

variable "user_host" {
    type = string
    default = "ec2-user"
}