variable "data" {
  type = "list"
  default = [
    "A", "B", "C"
  ]
}

output "data[0]" {
  value = "${var.data[0]}"
}

output "data[1]" {
  value = "${var.data[1]}"
}

output "data[2]" {
  value = "${var.data[2]}"
}
