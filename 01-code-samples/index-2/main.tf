
variable "values" {
  type = "list"
  default = [0]
}

output "v0" {
  value = index(var.values, 0)
}
