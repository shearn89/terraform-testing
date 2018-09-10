variable "region" {
  default = "eu-west-1"
}

variable "ami" {
  default = "ami-3548444c"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "devnet_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "tf-devnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.devnet_vpc.id}"
  tags {
    Name = "devnet"
  }
}

resource "aws_subnet" "devnet_subnet" {
  vpc_id = "${aws_vpc.devnet_vpc.id}"
  cidr_block = "172.16.10.0/24"
  tags {
    Name = "tf-devsubnet"
  }
  depends_on = [ "aws_internet_gateway.gw" ]
}

resource "aws_main_route_table_association" "devnet" {
  vpc_id = "${aws_vpc.devnet_vpc.id}"
  route_table_id = "${aws_route_table.devnet.id}"
}

resource "aws_route_table" "devnet" {
  vpc_id = "${aws_vpc.devnet_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    Name = "devnet"
  }
}

resource "aws_key_pair" "default_ssh_key" {
  key_name   = "default"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrYdacjowCFgd3DMWbs6zYENQZrDofCHlsf6u7PLNQ9lyAkPJnkXWPo9ya2GJWOIQGC3r07KgRs9OR1jdPI+e+XR69NDwNqxD2sxvPWS3VQnj/jiwxV/XZZkfz2zHpejUU/aHgTc3CP9gDXPTZiipKazUYQbNyE2Z9oxBTyd3ykLvBaPPz9w9NLBpxVxAgbHxKCHRtwQ83F7S0CbctqVg3Z2W6ySenmgUWM23tjdG3wzMiPzSIlunkx3MmoTrDEQy1VMCAXY9EDYQOY19wEkETsyXvCcsiXdzj9UNu+cKV/dEPtRST5XEd4Aj0ozLIULh9e7RSvCYlaH3syKG9hzsd shearna@ALEXBLADE"
}

########## BASTION HOST ###########
## TODO: EBS VOLUMES?
resource "aws_instance" "bastion" {
  ami = "${var.ami}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.devnet_subnet.id}"
  associate_public_ip_address = true
  key_name = "${aws_key_pair.default_ssh_key.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}",
    "${aws_security_group.default.id}"
  ]
  tags {
    Name = "bastion"
  }
  private_dns = "bastion"
}

resource "aws_eip" "devnet_eip" {
  instance = "${aws_instance.bastion.id}"
  vpc = true
  depends_on = [ "aws_internet_gateway.gw" ]
}

output "elastic_ip" {
  value = "${aws_eip.devnet_eip.public_ip}"
}

########## sec group #####
resource "aws_security_group" "default" {
  name = "dev-default"
  description = "devnet allow all"
  vpc_id = "${aws_vpc.devnet_vpc.id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }
}

resource "aws_security_group" "bastion" {
  name = "bastion"
  description = "Bastion host rules"
  vpc_id = "${aws_vpc.devnet_vpc.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

########## DEV NODES ##############
resource "aws_instance" "ipa-01" {
  ami = "${var.ami}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.devnet_subnet.id}"
  associate_public_ip_address = false
  key_name = "${aws_key_pair.default_ssh_key.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.default.id}"
  ]
  tags {
    Name = "ipa-01"
  }
  private_dns = "ipa-01"
}

resource "aws_instance" "ipa-02" {
  ami = "${var.ami}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.devnet_subnet.id}"
  associate_public_ip_address = false
  key_name = "${aws_key_pair.default_ssh_key.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.default.id}"
  ]
  tags {
    Name = "ipa-02"
  }
  private_dns = "ipa-02"
}

