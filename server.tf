module "ansible" {
	source = "radekg/ansible/provisioner"
	version = "2.3.0"
}

provider "aws" {
	profile                     = "default"
	region                      = "us-east-1"
	skip_credentials_validation = true
}

resource "aws_key_pair" "deployer" {
	key_name = "deployer_key"
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhNjrXCzxWsTwSFf+FFGktIS1sEezuq/6fPqLTPl+ezTdzhl4cbmYmHz0HCpK7d8wq7gCOF+K7ih4sMm7MRfhrlYKn334JFrL4IBiU/IThW/umI+Zzy8rpPFd6y5Xv8NFKcSssgVwfbZSyEKFG6wP060TZBAJ8UFM46B6OxnOkUnAJyCuEPXyKci5WZmfg/vZAA+TwFOXVEMxBBaFj2riUL8EOo1irZuV8GdJyDowp36Jo3B5mJ35eKvExBY2Vqo0kaUZId5CGJjhVesLKT4HBddUBvXOiG2TLap4kxRT6CR0287WjybI1LMj5eVGsTFWIN/dtQdQx9bIe1BLVvhZ9 ec2-user@ip-172-31-19-217.ec2.internal"
}

resource "aws_instance" "terraform_example" {
	ami = "ami-0b69ea66ff7391e80"
	instance_type = "t2.micro"
	key_name = "${aws_key_pair.deployer.key_name}"
	
	provisioner "local-exec" {
		connection {
			user = "ansible"
			host = "127.0.0.1"
		}
		command = "sudo echo '[nodes]\n${aws_instance.terraform_example.public_ip}' > /etc/ansible/hosts"
	}

	provisioner "remote-exec" {
		connection {
			host = "${aws_instance.terraform_example.public_ip}"
			user = "ec2-user"
			private_key = "${file("./.ssh/id_rsa")}"
		}

		inline = [
			"sudo yum update -y",
			"sudo yum install python -y"
		]
	}
	
	provisioner "ansible" {
		plays {
			playbook {
				file_path = "/home/ec2-user/mean.yaml"
			}
			inventory_file = "/etc/ansible/hosts"
		}
		
		ansible_ssh_settings {
			connection_attempts = 3
			insecure_no_strict_host_key_checking = true
		}
	}
}
