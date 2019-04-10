
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

output "my-ip" {
  value = "${chomp(data.http.myip.body)}"
}
