##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
module "vpc" {
  source = ".\\modules\\vpc"
  name   = "${var.environment_tag}"

  cidr = "${var.network_address_space}"
  azs  = "${slice(data.aws_availability_zones.available.names,0,var.subnet_count)}"

  tags {
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

# SECURITY GROUPS #
resource "aws_security_group" "elb-sg" {
  name   = "nginx_elb_sg"
  vpc_id = "${module.vpc.vpc_id}"

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment_tag}-elb-sg"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

# Nginx security group 
resource "aws_security_group" "nginx-sg" {
  name   = "nginx_sg"
  vpc_id = "${module.vpc.vpc_id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.network_address_space}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment_tag}-nginx-sg"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

# LOAD BALANCER #
resource "aws_elb" "web" {
  name = "${var.environment_tag}-nginx-elb"

  subnets         = ["${module.vpc.public_subnets}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]
  instances       = ["${aws_instance.nginx.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags {
    Name        = "${var.environment_tag}-elb"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

# INSTANCES #
resource "aws_instance" "nginx" {
  count                  = "${var.instance_count}"
  ami                    = "ami-07683a44e80cd32c5"
  instance_type          = "t2.micro"
  # Function :: element
  subnet_id              = "${element(module.vpc.public_subnets,count.index % var.subnet_count)}"
  vpc_security_group_ids = ["${aws_security_group.nginx-sg.id}"]
  key_name               = "${var.private_key_name}"

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    content = <<EOF
access_key = ${module.bucket.iam_access_key_id}
secret_key = ${module.bucket.iam_access_key_secret}
use_https = True
bucket_location = US

EOF

    destination = "/home/ec2-user/.s3cfg"
  }

  provisioner "file" {
    content = <<EOF
/var/log/nginx/*log {
    daily
    rotate 10
    missingok
    compress
    sharedscripts
    postrotate
      INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
      /usr/bin/s3cmd sync /var/log/nginx/access.log-* s3://${module.bucket.bucket_id}/$INSTANCE_ID/nginx/
      /usr/bin/s3cmd sync /var/log/nginx/error.log-* s3://${module.bucket.bucket_id}/$INSTANCE_ID/nginx/
    endscript
}

EOF

    destination = "/home/ec2-user/nginx"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install nginx1.12 -y",
      "sudo yum install nginx -y",
      "sudo service nginx start",
      "sudo chkconfig nginx on",
      "sudo cp /home/ec2-user/.s3cfg /root/.s3cfg",
      "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
      "sudo amazon-linux-extras install epel -y",
      "sudo yum install python-pip -y",
      "sudo pip install s3cmd",
      "s3cmd get s3://${module.bucket.bucket_id}/website/index.html .",
      "s3cmd get s3://${module.bucket.bucket_id}/website/Globo_logo_Vert.png .",
      "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html",
      "sudo cp /home/ec2-user/Globo_logo_Vert.png /usr/share/nginx/html/Globo_logo_Vert.png",
      "sudo logrotate -f /etc/logrotate.conf"
    ]
  }

  tags {
    Name        = "${var.environment_tag}-nginx-${count.index + 1}"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

# S3 Bucket config#
module "bucket" {
  name = "${var.environment_tag}-${var.bucket_name}"

  source = ".\\modules\\s3"

  tags = {
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

resource "aws_s3_bucket_object" "website" {
  bucket = "${module.bucket.bucket}"
  key    = "/website/index.html"
  source = "./index.html"
}

resource "aws_s3_bucket_object" "graphic" {
  bucket = "${module.bucket.bucket}"
  key    = "/website/Globo_logo_Vert.png"
  source = "./Globo_logo_Vert.png"
}
