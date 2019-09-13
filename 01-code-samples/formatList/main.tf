locals {
  default = "default"
  a_list = ["a", "b", "c"]
  b_list = ["1", "2", "3"]
}
output "out1" {
  value = formatlist("%s--->%s", local.a_list, local.b_list)
}

output "out2" {
  value = formatlist("%s--->%s", local.default, local.b_list)
}

output "out3" {
  value = formatlist("%s--->%s", local.default, local.default)
}
