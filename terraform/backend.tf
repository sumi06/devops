terraform {
  backend "s3" {
    bucket = "terraform-sumi-11"
    key    = "terraform-sumi-11/backend"
    region = "us-east-1"
  }
}