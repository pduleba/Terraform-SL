variable "instance_content_path" {
  default = "out/content.zip"
}

data "archive_file" "zip" {
  type        = "zip"
  output_path = "${path.module}/${var.instance_content_path}"
  source_dir  = "${path.module}/resources"
}


output "status" {
  value = "DONE"
}
