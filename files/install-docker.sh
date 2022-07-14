#!/bin/bash
set -ex
sudo yum update -y
sudo yum install -y docker
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo usermod -a -G docker ec2-user