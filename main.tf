provider "aws" {
    access_key = "XXXXXX"
    secret_key = "XXXXXX"
    region = "us-east-1"
}

resource "aws_key_pair" "mykey" {
    key_name = "terraform-ansible-key1"
    #public_key = file("C:/Users/username/.ssh/id_rsa.pub")
    public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "ssh-allow" {
    name = "allow-ssh-ansible"
    description = "Allow only ssh port"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "http-allow" {
    name = "allow-http-ansible"
    description = "Allow only http port"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "servers" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    key_name = aws_key_pair.mykey.key_name
    vpc_security_group_ids = [aws_security_group.ssh-allow.id,aws_security_group.http-allow.id]

    connection {
                type     = "ssh"
                user     = "ec2-user"
                private_key = file("~/.ssh/id_rsa")
                host = aws_instance.servers.public_ip
        }
        provisioner "file" {
    		source      = "main.yaml"
		destination = "/home/ec2-user/main.yaml"
  	}

	provisioner "remote-exec" {
    		inline = [
			"sudo yum install git -y",
			"sudo yum install python3 -y",
			"sudo pip3 install --upgrade pip",
			"sudo pip3 install ansible",
			"ansible-galaxy collection install git+https://github.com/lavatech321/ansible-collection-terraform.git,main",
			"ansible-galaxy collection install community.mysql",
			"ansible-galaxy collection install ansible.posix",
   			"sudo hostnamectl set-hostname server.example.com",	
			"ansible-playbook /home/ec2-user/main.yaml",
   		 ]
  	}
}

output "public_ip" {
	value = "Public IP address: ${aws_instance.servers.public_ip}"
}

output "sshkey" {
	value = "SSH Key location: ~/.ssh/id_rsa"
}

