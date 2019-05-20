variable "items" {
  type = "list"
  default = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f"
  ]
}

output "items" {
  value = "${var.items}"
}

output "items length" {
  value = "${length(var.items)}"
}

output "slice(items, 0, 3)" {
  value = "${slice(var.items, 0, 3)}"
}

output "lookup(items, 3, 6)" {
  value = "${slice(var.items, 3, 6)}"
}
