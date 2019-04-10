variable "dictionary" {
  type = "map"
  default = {
    "a" = "A"
    "b" = "B"
    "c" = "C"
  }
}


output "lookup(dictionary, 'a')" {
  value = "${lookup(var.dictionary, "a")}"
}

output "lookup(dictionary, 'b')" {
  value = "${lookup(var.dictionary, "b")}"
}

output "lookup(dictionary, 'c')" {
  value = "${lookup(var.dictionary, "c")}"
}
