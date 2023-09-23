terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "INFRANAME-VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "INFRANAME-VPC"
  }
}

resource "aws_subnet" "INFRANAME-SUBNET-PUBLIC" {
  vpc_id     = "${aws_vpc.INFRANAME-VPC.id}"
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "INFRANAME-SUBNET-PUBLIC"
  }
}

resource "aws_subnet" "INFRANAME-SUBNET-AZ-A" {
  vpc_id            = "${aws_vpc.INFRANAME-VPC.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "INFRANAME-SUBNET-AZ-A"
  }
}

resource "aws_subnet" "INFRANAME-SUBNET-AZ-B" {
  vpc_id            = "${aws_vpc.INFRANAME-VPC.id}"
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "INFRANAME-SUBNET-AZ-B"
  }
}

resource "aws_subnet" "INFRANAME-SUBNET-AZ-C" {
  vpc_id            = "${aws_vpc.INFRANAME-VPC.id}"
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "INFRANAME-SUBNET-AZ-C"
  }
}

resource "aws_internet_gateway" "INFRANAME-IGW" {
  tags = {
    Name = "INFRANAME-IGW"
  }
}

resource "aws_internet_gateway_attachment" "INFRANAME-IGW-ATTACH" {
  vpc_id             = "${aws_vpc.INFRANAME-VPC.id}"
  internet_gateway_id = "${aws_internet_gateway.INFRANAME-IGW.id}"
}

resource "aws_route_table" "INFRANAME-RTB-PUBLIC" {
  vpc_id = "${aws_vpc.INFRANAME-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.INFRANAME-IGW.id}"
  }

  tags = {
    Name = "INFRANAME-RTB-PUBLIC"
  }
}

resource "aws_eip" "INFRANAME-EIP" {
}


resource "aws_route_table_association" "INFRANAME-RTB-PRIVATE-ASSOC1" {
  subnet_id       = "${aws_subnet.INFRANAME-SUBNET-AZ-A.id}"
  route_table_id  = "${aws_route_table.INFRANAME-RTB-PUBLIC.id}"
}

resource "aws_route_table_association" "INFRANAME-RTB-PRIVATE-ASSOC2" {
  subnet_id       = "${aws_subnet.INFRANAME-SUBNET-AZ-B.id}"
  route_table_id  = "${aws_route_table.INFRANAME-RTB-PUBLIC.id}"
}

resource "aws_route_table_association" "INFRANAME-RTB-PRIVATE-ASSOC3" {
  subnet_id       = "${aws_subnet.INFRANAME-SUBNET-AZ-C.id}"
  route_table_id  = "${aws_route_table.INFRANAME-RTB-PUBLIC.id}"
}

resource "aws_route_table_association" "INFRANAME-RTB-PUBLIC-ASSOC" {
  subnet_id       = "${aws_subnet.INFRANAME-SUBNET-PUBLIC.id}"
  route_table_id  = "${aws_route_table.INFRANAME-RTB-PUBLIC.id}"
}

resource "aws_security_group" "INFRANAME-SG-REVERSE" {
  vpc_id = "${aws_vpc.INFRANAME-VPC.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.INFRANAME-SG-ADMIN.id}"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "INFRANAME-SG-WEB"
  }
}

resource "aws_security_group" "INFRANAME-SG-PROXY" {
  vpc_id = "${aws_vpc.INFRANAME-VPC.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.INFRANAME-SG-ADMIN.id}"]
  }
  ingress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    security_groups = ["${aws_security_group.INFRANAME-SG-WEB.id}"]
   }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "INFRANAME-SG-PUBLIC"
  }
}

resource "aws_security_group" "INFRANAME-SG-ADMIN" {
  vpc_id = "${aws_vpc.INFRANAME-VPC.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "INFRANAME-SG-LOAD-ADMIN"
  }
}

resource "aws_security_group" "INFRANAME-SG-WEB" {
  vpc_id = "${aws_vpc.INFRANAME-VPC.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.INFRANAME-SG-ADMIN.id}"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.INFRANAME-SG-REVERSE.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "INFRANAME-SG-WEB"
  }
}

resource "aws_instance" "INFRANAME-INSTANCE-PUBLIC-PROXY" {
  subnet_id                      = "${aws_subnet.INFRANAME-SUBNET-PUBLIC.id}"
  instance_type                  = "t2.micro"
  ami                            = "ami-04cb4ca688797756f"
  key_name                       = "frist-instance"
  vpc_security_group_ids         = ["${aws_security_group.INFRANAME-SG-PROXY.id}"]
  associate_public_ip_address    = true

  user_data = file ("install_squid.sh") 
  tags = {
    Name = "INFRANAME-INSTANCE-PUBLIC-PROXY"
  }
}
resource "aws_instance" "INFRANAME-INSTANCE-PUBLIC-ADMIN" {
  subnet_id                      = "${aws_subnet.INFRANAME-SUBNET-PUBLIC.id}"
  instance_type                  = "t2.micro"
  ami                            = "ami-04cb4ca688797756f"
  key_name                       = "frist-instance"
  vpc_security_group_ids         = ["${aws_security_group.INFRANAME-SG-ADMIN.id}"]
  associate_public_ip_address    = true
  tags = {
    Name = "INFRANAME-INSTANCE-PUBLIC-ADMIN"
  }
}
resource "aws_instance" "INFRANAME-INSTANCE-PUBLIC-PROXY-REVERSE" {
        subnet_id = "${aws_subnet.INFRANAME-SUBNET-PUBLIC.id}"
        instance_type = "t2.micro"
        ami = "ami-04cb4ca688797756f"
        key_name = "frist-instance"
        vpc_security_group_ids = ["${aws_security_group.INFRANAME-SG-REVERSE.id}"]
        associate_public_ip_address = true
        user_data = "${templatefile("reverse.sh", { 
            web1_ip = "${aws_instance.INFRANAME-INSTANCE-AZ-A.private_ip}"
            web2_ip = "${aws_instance.INFRANAME-INSTANCE-AZ-B.private_ip}" 
            web3_ip = "${aws_instance.INFRANAME-INSTANCE-AZ-C.private_ip}" })}"
        tags = {
                Name = "INFRANAME-INSTANCE-PUBLIC-PROXY-REVERSE"
        }
}

resource "aws_instance" "INFRANAME-INSTANCE-AZ-A" {
  subnet_id                      = "${aws_subnet.INFRANAME-SUBNET-AZ-A.id}"
  instance_type                  = "t2.micro"
  ami                            = "ami-04cb4ca688797756f"
  key_name                       = "frist-instance"
  vpc_security_group_ids         = ["${aws_security_group.INFRANAME-SG-WEB.id}"]
  associate_public_ip_address    = false
  user_data = "${templatefile("web.sh", { web_ip = "${aws_instance.INFRANAME-INSTANCE-PUBLIC-PROXY.private_ip}" })}"
  tags = {
    Name = "INFRANAME-INSTANCE-AZ-A"
  }
}

resource "aws_instance" "INFRANAME-INSTANCE-AZ-B" {
  subnet_id                      = "${aws_subnet.INFRANAME-SUBNET-AZ-B.id}"
  instance_type                  = "t2.micro"
  ami                            = "ami-04cb4ca688797756f"
  key_name                       = "frist-instance"
  vpc_security_group_ids         = ["${aws_security_group.INFRANAME-SG-WEB.id}"]
  associate_public_ip_address    = false
  user_data = "${templatefile("web.sh", { web_ip = "${aws_instance.INFRANAME-INSTANCE-PUBLIC-PROXY.private_ip}" })}"
  tags = {
    Name = "INFRANAME-INSTANCE-AZ-B"
  }
}

resource "aws_instance" "INFRANAME-INSTANCE-AZ-C" {
  subnet_id                      = "${aws_subnet.INFRANAME-SUBNET-AZ-C.id}"
  instance_type                  = "t2.micro"
  ami                            = "ami-04cb4ca688797756f"
  key_name                       = "frist-instance"
  vpc_security_group_ids         = ["${aws_security_group.INFRANAME-SG-WEB.id}"]
  associate_public_ip_address    = false
  user_data = "${templatefile("web.sh", { web_ip = "${aws_instance.INFRANAME-INSTANCE-PUBLIC-PROXY.private_ip}" })}"
  tags = {
    Name = "INFRANAME-INSTANCE-AZ-C"
  }
}

