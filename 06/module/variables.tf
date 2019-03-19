##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
variable "private_key_path" {}
variable "private_key_name" {}
variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "billing_code_tag" {}
variable "environment_tag" {}
variable "bucket_name" {}

variable "instance_count" {
  default = 3
}

variable "subnet_count" {
  default = 3
}

