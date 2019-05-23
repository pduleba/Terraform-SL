
resource "random_string" "password" {
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html
  length = 10
  upper = true
  min_upper = 1
  lower = true
  min_lower = 1
  number = true
  min_numeric = 1
  special = true
  min_special = 1
  override_special = "/@\" "
}

locals {
  password = "${random_string.password.result}"
}

output "password" {
  value = "${local.password}"
}
