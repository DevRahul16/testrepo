    terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}



resource "aws_security_group" "sec_ansible" {
  name        = "sec_ansible"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  

 ingress {
   description = "Allow HTTP from anywhere"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
 ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sec_ansible"
  }
}

resource "aws_instance" "ansible-server" {
  ami                         = "ami-0b982602dbb32c5bd"
  instance_type               = "t2.micro"
  key_name                    = "Linux07"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.sec_ansible.id]
  associate_public_ip_address = true
  tags = {
        Name = "Ansible-Server"
    }
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install ansible -y
              # Write private key
              echo "[all]" > /etc/ansible/hosts
              echo "pc1 ansible_host=${aws_instance.pc1.private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/Ammu.pem" >> /etc/ansible/hosts
              echo "pc2 ansible_host=${aws_instance.pc2.private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/Ammu.pem" >> /etc/ansible/hosts

                EOF

}

resource "aws_instance" "pc1" {
  ami                         = "ami-0b982602dbb32c5bd"
  instance_type               = "t2.micro"
  key_name                    = "Linux07"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.sec_ansible.id]
  associate_public_ip_address = true


  tags = {
    Name = "PC-1"
  }
}

resource "aws_instance" "pc2" {
  ami                         = "ami-0b982602dbb32c5bd"
  instance_type               = "t2.micro"
  key_name                    = "Linux07"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.sec_ansible.id]
  associate_public_ip_address = true


  tags = {
    Name = "PC-2"
  }
}

output "ansible_server_ipaddress" {
  value = aws_instance.ansible-server.public_ip
  
}