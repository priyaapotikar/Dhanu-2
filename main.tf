provider "aws" {
  version = "~> 2.0"
  access_key = "${var.access_key}" 
  secret_key = "${var.secret_key}" 
  region     = "${var.region}"
}



# create the VPC
resource "aws_vpc" "Brijesh_VPC" {
  cidr_block           = "${var.vpcCIDRblock}"
  instance_tenancy     = "${var.instanceTenancy}" 
  enable_dns_support   = "${var.dnsSupport}"
  enable_dns_hostnames = "${var.dnsHostNames}"
tags = {
    Name = "Brijesh_VPC"
}
} 
# end resource



# create the public 1 Subnet
resource "aws_subnet" "Brijesh_Subnet" {
 count = "${length(var.subnetCIDRblockone)}"
  vpc_id                  = "${aws_vpc.Brijesh_VPC.id}"
  cidr_block              = "${var.subnetCIDRblockone[count.index]}"
  map_public_ip_on_launch = "${var.mapPublicIP}" 
  availability_zone       = "${var.availabilityZoneone[count.index]}"

tags = {
   Name = "Brijesh publice 1 Subnet"
}
} 
# end resource



# create the private  Subnet
resource "aws_subnet" "Brijesh_Subnet_private" {
  vpc_id                  = "${aws_vpc.Brijesh_VPC.id}"
  cidr_block              = "${var.subnetCIDRblocktwo}"
  availability_zone       = "${var.availabilityZonetwo}"
tags = {
   Name = "Brijesh Private Subnet"
}
} 
# end resource





# Create the public Security Group
resource "aws_security_group" "My_VPC_Security_Group" {
  vpc_id       = "${aws_vpc.Brijesh_VPC.id}"
  name         = "Brijesh VPC Security Group"
  description  = "Brijesh VPC Security Group"
  
  # allow ingress of port 22
  ingress {
    cidr_blocks = "${var.ingressCIDRblock}"  
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  } 
  
ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.Brijesh_alb_sg.id}"]
  } 
  
  
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
   Name = "Brijesh VPC Security Group"
   Description = "Brijesh VPC Security Group"
}
} 
# end resource

# Create the Private Security Group
resource "aws_security_group" "My_VPC_Priavte_Security_Group" {
  vpc_id       = "${aws_vpc.Brijesh_VPC.id}"
  name         = "Brijesh Private VPC Security Group"
  description  = "Brijesh Priavte VPC Security Group"
  
ingress {
    cidr_blocks = "${var.ingressCIDRblock}"  
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  
    ingress {
    cidr_blocks = "${var.ingressCIDRblock}"  
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }
  
  
  
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
   Name = "Brijesh Private VPC Security Group"
   Description = "Brijesh  Private VPC Security Group"
}
} 
# end resource


# Create the Internet Gateway
resource "aws_internet_gateway" "Brijesh_VPC_GW" {
 vpc_id = "${aws_vpc.Brijesh_VPC.id}"
 tags = {
        Name = "Brijesh VPC Internet Gateway"
}
} 
# end resource



# Create the Route Table
resource "aws_route_table" "Brijesh_VPC_route_table" {
 vpc_id = "${aws_vpc.Brijesh_VPC.id}"
 tags = {
        Name = "Brijesh VPC Route Table"
}
} 
# end resource



# Create the Internet Access
resource "aws_route" "My_VPC_internet_access" {
  route_table_id         = "${aws_route_table.Brijesh_VPC_route_table.id}"
  destination_cidr_block = "${var.destinationCIDRblock}"
  gateway_id             = "${aws_internet_gateway.Brijesh_VPC_GW.id}"
} 
# end resource


# Associate the Route Table with the Subnet
resource "aws_route_table_association" "My_VPC_association" {
  count = "${length(var.subnetCIDRblockone)}"
  subnet_id     = "${element(aws_subnet.Brijesh_Subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.Brijesh_VPC_route_table.id}"
} 
# end resource













######## Create Public Ec2 
resource "aws_instance" "terraformec2" {
  ami           = "${var.amiid}"
  instance_type = "${var.instype}"
  key_name = "brijeshterra"
  count = "${length(var.subnetCIDRblockone)}"
  subnet_id     = "${element(aws_subnet.Brijesh_Subnet.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.My_VPC_Security_Group.id}"]
  
  
  tags = {
    Name = "Terraform Ec2 Instance"
  }


  user_data = <<EOF
#!/bin/sh
sudo apt-get update
sudo apt-get install -y apache2 mysql-client
sudo echo "this is my page 1" > /var/www/html/index.html
EOF


lifecycle {
    create_before_destroy = true
  }

}

######## End  Ec2



### ALB Start

resource "aws_lb" "Brijesh_alb" {
  name               = "Brijesh-myalb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  count              = "${length(var.subnetCIDRblockone)}"
  subnets            =  ["${aws_subnet.Brijesh_Subnet[0].id}","${aws_subnet.Brijesh_Subnet[1].id}"]
  security_groups    = ["${aws_security_group.Brijesh_alb_sg.id}"]  



  }



resource "aws_lb_listener" "alb_listener" {  
  count = "${length(var.subnetCIDRblockone)}"
  load_balancer_arn = "${aws_lb.Brijesh_alb[count.index].arn}"
  port              = "80"
  protocol          = "HTTP"

  
  default_action {    
    target_group_arn = "${aws_lb_target_group.Brijesh_alb_tg.arn}"
    type             = "forward"  
  }
}


resource "aws_lb_target_group" "Brijesh_alb_tg" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "Brijeshalbtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.Brijesh_VPC.id}"
  target_type = "instance"
}


resource "aws_lb_target_group_attachment" "Brijesh_tg_attachment1" {
  target_group_arn = "${aws_lb_target_group.Brijesh_alb_tg.arn}"
  target_id        = "${aws_instance.terraformec2[0].id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "Brijesh_tg_attachment2" {
  target_group_arn = "${aws_lb_target_group.Brijesh_alb_tg.arn}"
  target_id        = "${aws_instance.terraformec2[1].id}"
  port             = 80
}




resource "aws_security_group" "Brijesh_alb_sg" {
  name   = "Brijesh-alb-sg"
 vpc_id      = "${aws_vpc.Brijesh_VPC.id}"
}
resource "aws_security_group_rule" "http_allow" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.Brijesh_alb_sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.Brijesh_alb_sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}






