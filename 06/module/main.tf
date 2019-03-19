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
resource "aws_vpc" "vpc" {
  cidr_block = "${var.network_address_space}"

  tags {
    Name        = "${var.environment_tag}-vpc"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment_tag}-igw"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

resource "aws_subnet" "subnet" {
  # Count variable
  count                   = "${var.subnet_count}"
  # Function :: cidrsubnet
  cidr_block              = "${cidrsubnet(var.network_address_space, 8, count.index + 1)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index%length(data.aws_availability_zones.available.names)]}"

  tags {
    Name        = "${var.environment_tag}-subnet-${count.index + 1}"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name        = "${var.environment_tag}-rtb"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

resource "aws_route_table_association" "rta-subnet" {
  count          = "${var.subnet_count}"
  # Function :: element
  subnet_id      = "${element(aws_subnet.subnet.*.id,count.index)}"
  route_table_id = "${aws_route_table.rtb.id}"
}

# SECURITY GROUPS #
resource "aws_security_group" "elb-sg" {
  name   = "nginx_elb_sg"
  vpc_id = "${aws_vpc.vpc.id}"

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
  vpc_id = "${aws_vpc.vpc.id}"

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

  subnets         = ["${aws_subnet.subnet.*.id}"]
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
  subnet_id              = "${element(aws_subnet.subnet.*.id,count.index % var.subnet_count)}"
  vpc_security_group_ids = ["${aws_security_group.nginx-sg.id}"]
  key_name               = "${var.private_key_name}"

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    content = <<EOF
access_key = ${aws_iam_access_key.write_user.id}
secret_key = ${aws_iam_access_key.write_user.secret}
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
      /usr/bin/s3cmd sync /var/log/nginx/access.log-* s3://${aws_s3_bucket.web_bucket.id}/$INSTANCE_ID/nginx/
      /usr/bin/s3cmd sync /var/log/nginx/error.log-* s3://${aws_s3_bucket.web_bucket.id}/$INSTANCE_ID/nginx/
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
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html .",
      "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/Globo_logo_Vert.png .",
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
resource "aws_iam_user" "write_user" {
  name          = "${var.environment_tag}-s3-write-user"
  force_destroy = true
}

resource "aws_iam_access_key" "write_user" {
  user = "${aws_iam_user.write_user.name}"
}

resource "aws_iam_user_policy" "write_user_pol" {
  name = "write"
  user = "${aws_iam_user.write_user.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}",
                "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}/*"
            ]
        }
   ]
}
EOF
}

resource "aws_s3_bucket" "web_bucket" {
  bucket        = "${var.environment_tag}-${var.bucket_name}"
  acl           = "private"
  force_destroy = true

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}/*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_user.write_user.arn}"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}",
                "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}/*"
            ]
        }
    ]
}
EOF

  tags {
    Name        = "${var.environment_tag}-web_bucket"
    BillingCode = "${var.billing_code_tag}"
    Environment = "${var.environment_tag}"
  }
}

resource "aws_s3_bucket_object" "website" {
  bucket = "${aws_s3_bucket.web_bucket.bucket}"
  key    = "/website/index.html"
  source = "./index.html"
}

resource "aws_s3_bucket_object" "graphic" {
  bucket = "${aws_s3_bucket.web_bucket.bucket}"
  key    = "/website/Globo_logo_Vert.png"
  source = "./Globo_logo_Vert.png"
}
