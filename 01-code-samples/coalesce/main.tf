
variable "empty_sting" {
 default = ""
}

variable "not_empty_sting" {
  default = "value"
}

output "test_1_empty" {
  value = "${coalesce(var.empty_sting, var.not_empty_sting)}"
}

output "test_1_and_2_empty" {
  value = "${coalesce(var.empty_sting, var.empty_sting, var.not_empty_sting)}"
}

output "test_1_not_empty" {
  value = "${coalesce(var.not_empty_sting, var.empty_sting)}"
}
