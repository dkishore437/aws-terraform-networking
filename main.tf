data "aws_availability_zones" "available" {}

resource "aws_vpc" "tf_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support = true

 tags {
  name = "tf_vpc"
  }
}

resource "aws_internet_gateway" "tf_gateway" {
   vpc_id = "${aws_vpc.tf_vpc.id}"

   tags {
    name = "tf_gateway"
   }
}


resource "aws_route_table" "tf_public_rt" {
  vpc_id = "${aws_vpc.tf_vpc.id}"

  route {
       cidr_block = "0.0.0.0/0"
       gateway_id = "${aws_internet_gateway.tf_gateway.id}"
    }
   tags {
    name = "tf_public"
   }
  }

resource "aws_default_route_table" "private_tf_route" {
  default_route_table_id = "${aws_vpc.tf_vpc.id}"

  tags {
      name = "tf_private"
    }
 }

resource "aws_subnet" "tf_public_subnet" {
   count = 2
   vpc_id = "${aws_vpc.tf_vpc.id}"
   cidr_block = "${var.public_cidrs[count.index]}"
   map_public_ip_on_launch = true
   availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
   tags {
       Name = "tf_public_${count.index + 1}"
   }
}

resource "aws_route_table_association" "tf_public_assoc" {
    count = "${aws_subnet.tf_public_subnet.count}"
    subnet_id = "${aws_subnet.tf_public_subnet.*.id[count.index]}"
    route_table_id = "${aws_route_table.tf_public_rt.id}"
}

resource "aws_security_group" "tf_public_sg" {
    name = "tf_public_sg"
    description = "used for access to public instances"
    vpc_id = "${aws_vpc.tf_vpc.id}"

    #SSH

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.accessip}"]
     }

     #HTTP

     ingress {
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_blocks = ["${var.accessip}"]
     }

     egress {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
}
}
