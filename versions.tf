terraform {
  backend "s3" {
    bucket = "devopstest-terraform" # Will be overridden from build
    key    = "terraform"          # Will be overridden from build
    region = "us-east-1"
  }
}
