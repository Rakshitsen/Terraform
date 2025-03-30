resource "aws_instance" "test-instance" {
  count = 3  # Creates 3 instances
  ami = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  key_name = "us-east-1"
  vpc_security_group_ids = ["default", "launch-wizard-7"]

  user_data = <<-EOF
  #! /bin/bash
  sudo apt-get update
  sudo git clone http://github.com/lerndevops/labs
  sudo chmod -R 775 labs
  sudo labs/cloud/setup-user.sh
  EOF

  tags = {
    Name = "demoinstance-${count.index + 1}"
  }
}


