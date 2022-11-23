terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.40.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

#vpc
resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_cidr

  tags = {
    "Name" = "vpc1"
  }
}


#public subnet 1
resource "aws_subnet" "public_subnet1" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.public_subnet1
    availability_zone = var.az1

    tags = {
      "Name" = "public_subnet1"
    }
}

# public subnet 2
resource "aws_subnet" "public_subnet2" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.public_subnet2
    availability_zone = var.az2

    tags = {
      "Name" = "public_subnet2"
    }
}

# private subnet 1
resource "aws_subnet" "private_subnet1" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.private_subnet1
    availability_zone = var.az1

    tags = {
      "Name" = "private_subnet1"
    }
}

# private subnet 2
resource "aws_subnet" "private_subnet2" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.private_subnet2
    availability_zone = var.az2

    tags = {
      "Name" = "private_subnet2"
    }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc1.id

    tags = {
        "Name" = "igw"
    } 
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1.id
  

  tags = {
    Name = "nat-gateway"
  }



  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


# public route table
resource "aws_route_table" "routepublic" {
    vpc_id = aws_vpc.vpc1.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      "Name" = "public-route-table"
    }
  
}

#private route table 
resource "aws_route_table" "routeprivate" {
    vpc_id = aws_vpc.vpc1.id

    tags = {
      "Name" = "private-route-table"
    }

}

resource "aws_route" "public-igw" {
    route_table_id = aws_route_table.routepublic.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  
}

resource "aws_route" "private-nat" {
    route_table_id = aws_route_table.routeprivate.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  
}


# public subnet 1 association
resource "aws_route_table_association" "publicrt1" {
    subnet_id = aws_subnet.public_subnet1.id
    route_table_id = aws_route_table.routepublic.id
}

# public subnet 2 association
resource "aws_route_table_association" "publicrt2" {
    subnet_id = aws_subnet.public_subnet2.id
    route_table_id = aws_route_table.routepublic.id
}

# private subnet 1 association
resource "aws_route_table_association" "privatert1" {
    subnet_id = aws_subnet.private_subnet1.id
    route_table_id = aws_route_table.routeprivate.id
}

# private subnet 2 association
resource "aws_route_table_association" "privatert2" {
    subnet_id = aws_subnet.private_subnet2.id
    route_table_id = aws_route_table.routeprivate.id
}

# security for servers, databases, vpc

resource "aws_security_group" "sgvpc" {
    name = "sgvpc"
    description = "allow inbound HTTP traffic"
    vpc_id = aws_vpc.vpc1.id

# HTTP inbound rules
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
# outbound rules
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = {
          "Name" = "sgvpc"
    }   
}

# security group of web servers

resource "aws_security_group" "web_sg" {
    name = "webserver_sg"
    description = "allow inbound traffic from ALB"
    vpc_id = aws_vpc.vpc1.id
# allow inbound traffic from web
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.sgvpc.id]
    }

    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "webserver_sg"
    }
}

# databases security group

resource "aws_security_group" "database_sg" {
    name = "database_sg"
    description = "allow inbound traffic from ALB"
    vpc_id = aws_vpc.vpc1.id

    # allow traffic from ALB
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.web_sg.id]
    }

    egress {
        from_port = 32768
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "database_sg"
    }
}

# Instances

resource "aws_instance" "instance-1" {
    ami = var.ec2_ami
    instance_type = var.ec2_type
    key_name = "kaity-demo-2"
    availability_zone = var.az1
    subnet_id = aws_subnet.public_subnet1.id
    vpc_security_group_ids = [aws_security_group.web_sg.id]

    tags = {
        Name = "ec2_1"
    }

}

resource "aws_instance" "instance-2" {
    ami = var.ec2_ami
    instance_type = var.ec2_type
    key_name = "kaity-demo-2"
    availability_zone = var.az2
    subnet_id = aws_subnet.public_subnet2.id
    vpc_security_group_ids = [aws_security_group.web_sg.id]

    tags = {
        Name = "ec2_2"
    }

}

resource "aws_db_subnet_group" "rdsgroup" {
    name = "main"
    subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]

    tags = {
        Name = "rds_subnet_group"
    }
}

# RDS instance
resource "aws_db_instance" "my_db" {
    allocated_storage = 10
    db_subnet_group_name = aws_db_subnet_group.rdsgroup.id
    engine = var.db_engine
    engine_version = var.db_engine_version
    instance_class = var.db_instance_class
    multi_az = false
    db_name = var.db_name
    username = var.db_username
    password = var.db_password
    skip_final_snapshot = true
    vpc_security_group_ids = [aws_security_group.database_sg.id]

}

resource "aws_db_instance" "my_db2" {
    allocated_storage = 10
    db_subnet_group_name = aws_db_subnet_group.rdsgroup.id
    engine = var.db_engine
    engine_version = var.db_engine_version
    instance_class = var.db_instance_class
    multi_az = false
    db_name = var.db_name2
    username = var.db_username
    password = var.db_password
    skip_final_snapshot = true
    availability_zone = var.az1
    vpc_security_group_ids = [aws_security_group.database_sg.id]

}

#ALB

resource "aws_lb_target_group" "external-tg" {
    name = "external-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc1.id
  
}

resource "aws_lb_target_group_attachment" "ec2-1-tg" {
    target_group_arn = aws_lb_target_group.external-tg.arn
    target_id = aws_instance.instance-1.id
    port = 80
} 

resource "aws_lb_target_group_attachment" "ec2-2-tg" {
    target_group_arn = aws_lb_target_group.external-tg.arn
    target_id = aws_instance.instance-2.id
    port = 80
} 

resource "aws_lb" "external_alb" {
    name = "external-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.sgvpc.id]
    subnets = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]

    tags = {
        "Name" = "external-alb"
    }
  
}

# ALB listener
resource "aws_lb_listener" "alb_listener" {
    load_balancer_arn = aws_lb.external_alb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.external-tg.arn
    }
}

# outputs
#dns of load balancer

output "alb_dns_name" {
    description = "DNS name of the load balancer"
    value = "${aws_lb.external_alb.dns_name}"
}

output "db_connect_string" {
    description = "RDS database connection string"
    value = "server=${aws_db_instance.my_db.address}; database=ExampleDB; Uid=${var.db_username}; Pws${var.db_password}"
    sensitive = true 
}