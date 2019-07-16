terraform {
  backend "local" {}
}

variable "profile" {default = "jenkins-pgs-admin-cli-profile"}
variable "region" {default = "eu-west-2"}

provider "aws" {
  profile = var.profile
  region  = var.region
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "user_id" {
  value = "${data.aws_caller_identity.current.user_id}"
}

output "arn" {
  value = "${data.aws_caller_identity.current.arn}"
}
