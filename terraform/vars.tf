variable "region" {
  default = "us-east-1"
}

variable "zone1" {
  default = "us-east-1a"
}

variable "ami_id" {
  type = map(any)
  default = {
    us-east-1 = "ami-084568db4383264d4"
    us-east-2 = "ami-04f167a56786e4b09"
  }
}

variable "web_user" {
  default = "ubuntu"
}