terraform {
  backend "local" {}
}

locals {
  ODD = 5
  EVEN = 2
  VALUES = ["a", "b", "c", "d"]
}

output "odd-modulo" {
  value = (local.ODD % 2)
}

output "even-modulo" {
  value = (local.EVEN % 2)
}

output "odd-divide-with-floor" {
  value = local.VALUES[floor(local.ODD / 2)]
}

output "even-divide-with-floor" {
  value = local.VALUES[floor(local.EVEN / 2)]
}

output "odd-divide-without-floor" {
  value = local.VALUES[local.ODD / 2]
}

output "even-divide-without-floor" {
  value = local.VALUES[local.EVEN / 2]
}
