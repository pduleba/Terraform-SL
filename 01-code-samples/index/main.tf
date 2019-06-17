
variable "values" {
  type = "list"
  default = [0]
}

output "v-1" {
  value = "${length(var.values) < 0 ? index(var.values, -1) : "---"}"
}

output "v0" {
  value = "${length(var.values) > 0 ? index(var.values, 0) : "---"}"
}

output "v1" {
  value = "${length(var.values) > 1 ? index(var.values, 1) : "---"}"
}
